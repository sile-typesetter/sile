use clap::CommandFactory;

use sile::cli::Cli;

fn main() -> sile::Result<()> {
    let app = Cli::command();
    let matches = app.get_matches();
    println!("Hello, world!");
    Ok(())
}
