#[cfg(feature = "cli")]
pub mod cli;

pub type Result<T> = anyhow::Result<T>;
