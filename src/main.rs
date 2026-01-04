use std::str::FromStr;

use tracing::Level;

mod config;
mod utils;

#[dotenvy::load(path = "./.env", required = true)]
#[tokio::main]
async fn main() {
    
    // Step 0. Initialization
    let config = config::Config::init().expect("Failed to initialize configuration");
    tracing_subscriber::fmt()
        .with_max_level(
            Level::from_str(&config.logs.level)
                .unwrap_or(Level::INFO)
        )
        .init();

    // Step 1. List all movies in Radarr
    let radarr_config = radarr::apis::configuration::Configuration {
        base_path: config.radarr.base_url.clone(),
        api_key: Some(radarr::apis::configuration::ApiKey {
            prefix: None,
            key: config.radarr.api_key,
        }),
        ..Default::default()
    };

    let movies = radarr::apis::movie_api::list_movie(&radarr_config, None, None, None).await;
    println!("Movies: {:#?}", movies.unwrap().len());
}