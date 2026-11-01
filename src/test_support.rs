//! Fixtures the crate's unit tests share.

use std::path::Path;

/// A directory symlink, or `false` when Windows withholds `SeCreateSymbolicLinkPrivilege`.
pub(crate) fn try_symlink_dir(original: impl AsRef<Path>, link: impl AsRef<Path>) -> bool {
    let original = original.as_ref();
    let link = link.as_ref();
    #[cfg(unix)]
    {
        std::os::unix::fs::symlink(original, link).unwrap();
        true
    }
    #[cfg(windows)]
    {
        match std::os::windows::fs::symlink_dir(original, link) {
            Ok(()) => true,
            Err(error) if error.raw_os_error() == Some(1314) => false,
            Err(error) => panic!("symlink_dir {}: {error}", link.display()),
        }
    }
}

/// A fresh repository on `main` with an identity, and a runner for git in it.
pub(crate) fn test_repo() -> (tempfile::TempDir, impl Fn(&[&str]) -> String) {
    let dir = tempfile::tempdir().unwrap();
    let repo = dir.path().to_path_buf();
    let git = move |args: &[&str]| {
        let out = std::process::Command::new("git").arg("-C").arg(&repo).args(args).output();
        let out = out.unwrap();
        assert!(out.status.success(), "git {args:?}");
        String::from_utf8(out.stdout).unwrap().trim().to_string()
    };
    git(&["init", "-q", "-b", "main"]);
    git(&["config", "user.email", "t@t"]);
    git(&["config", "user.name", "t"]);
    (dir, git)
}
