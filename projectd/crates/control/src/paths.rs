//! Filesystem locations for the control role.

use std::path::PathBuf;

pub fn data_dir() -> PathBuf {
    if let Ok(home) = std::env::var("PROJECTD_HOME") {
        return PathBuf::from(home);
    }
    #[cfg(target_os = "macos")]
    {
        dirs_fallback("Library/Application Support/projectd")
    }
    #[cfg(not(target_os = "macos"))]
    {
        if let Ok(xdg) = std::env::var("XDG_DATA_HOME") {
            return PathBuf::from(xdg).join("projectd");
        }
        dirs_fallback(".local/share/projectd")
    }
}

pub fn runtime_dir() -> PathBuf {
    if let Ok(home) = std::env::var("PROJECTD_HOME") {
        return PathBuf::from(home);
    }
    #[cfg(target_os = "macos")]
    {
        data_dir()
    }
    #[cfg(not(target_os = "macos"))]
    {
        if let Ok(xdg) = std::env::var("XDG_RUNTIME_DIR") {
            return PathBuf::from(xdg);
        }
        data_dir()
    }
}

pub fn sqlite_path() -> PathBuf {
    if let Ok(p) = std::env::var("PROJECTD_SQLITE") {
        return PathBuf::from(p);
    }
    data_dir().join("projectd.sqlite")
}

pub fn socket_path() -> PathBuf {
    if let Ok(p) = std::env::var("PROJECTD_SOCKET") {
        return PathBuf::from(p);
    }
    runtime_dir().join("projectd.sock")
}

pub fn providers_path() -> PathBuf {
    if let Ok(p) = std::env::var("PROJECTD_PROVIDERS_FILE") {
        return PathBuf::from(p);
    }
    data_dir().join("providers.toml")
}

fn dirs_fallback(rel: &str) -> PathBuf {
    let home = std::env::var("HOME").unwrap_or_else(|_| ".".into());
    PathBuf::from(home).join(rel)
}
