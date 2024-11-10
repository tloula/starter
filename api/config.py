"""
Armedis
App Configuration
"""

import datetime
from enum import Enum

from pydantic_settings import BaseSettings
from azure.appconfiguration import AzureAppConfigurationClient
from azure.core.credentials import TokenCredential
from azure.keyvault.secrets import SecretClient

from .singleton_meta import SingletonMeta


class CacheItem:

    def __init__(self, value: str) -> None:
        self.value: str = value
        self.time: datetime.datetime = datetime.datetime.now()

    def is_valid(self, duration_seconds: int) -> bool:
        elapsed_seconds = (datetime.datetime.now() - self.time).total_seconds()
        return elapsed_seconds < duration_seconds


class ConfigType(Enum):
    CONFIG = "Config"
    SECRET = "Secret"
    STATIC = "Static"


class Config(metaclass=SingletonMeta):

    MSI_CLIENT_ID = "b87ac48f-f38c-457f-85be-9501d7dd1f40"

    def __init__(self, credential: TokenCredential) -> None:
        self.static = Static()
        self.app_config = AzureAppConfigurationClient(self.static.azure_appconfig_endpoint,
                                                      credential)
        self.secrets = SecretClient(self.static.azure_keyvault_endpoint, credential)

        self._cache: dict[str, CacheItem] = {}

    def __getitem__(self, key: str) -> str:
        return self.get(key)

    def get(self,
            key: str,
            config_type: ConfigType = ConfigType.CONFIG,
            cache_duration_seconds: int | None = None) -> str:
        if cache_duration_seconds is None:
            cache_duration_seconds = self._get_cache_duration_seconds(key)
        if key not in self._cache or not self._cache[key].is_valid(cache_duration_seconds):
            self._cache[key] = CacheItem(self._get_value(config_type, key))
        return self._cache[key].value

    def _get_cache_duration_seconds(self, key: str) -> int:
        if key == "Config Cache Duration Seconds":
            return self.static.default_config_cache_duration_seconds
        return self.config_cache_duration_seconds

    def _get_value(self, config_type: ConfigType, key: str) -> str:
        if config_type == ConfigType.SECRET:
            return self.secrets.get_secret(key).value
        elif config_type == ConfigType.CONFIG:
            return self.app_config.get_configuration_setting(key).value
        elif config_type == ConfigType.STATIC:
            return getattr(self.static, key)
        else:
            raise ValueError(f"Invalid configuration type: {config_type}.")

    @property
    def config_cache_duration_seconds(self) -> int:
        return int(self["Config Cache Duration Seconds"])

    @property
    def application_insights_connection_string(self) -> str:
        return self.get("azure-application-insights-connection-string", ConfigType.SECRET, 86400)

    @property
    def postgresql_coordinator_url(self) -> str:
        return self.get("azure-cosmosdb-postgresql-coordinator-url", ConfigType.SECRET, 86400)

    @property
    def postgresql_password(self) -> str:
        return self.get("azure-cosmosdb-postgresql-password", ConfigType.SECRET, 86400)


class Static(BaseSettings):

    class Config:
        env_file = ".env"

    auth_algorithms: str
    auth_api_audience: str
    auth_jwks_url: str
    auth_issuer: str

    azure_appconfig_endpoint: str
    azure_keyvault_endpoint: str
    azure_postgresql_database_name: str

    default_config_cache_duration_seconds: int
