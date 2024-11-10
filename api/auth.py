"""
Armedis
API Authentication Utilities
"""

import uuid
from datetime import datetime
from typing import Optional

import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import SecurityScopes, HTTPAuthorizationCredentials, HTTPBearer
from opentelemetry import trace

from .config import Config


class UnauthorizedException(HTTPException):

    def __init__(self, detail: str):
        """Returns HTTP 403"""
        super().__init__(status.HTTP_403_FORBIDDEN, detail=detail)


class UnauthenticatedException(HTTPException):
    def __init__(self):
        super().__init__(status_code=status.HTTP_401_UNAUTHORIZED,
                         detail="Requires authentication")


class VerifyToken:
    """Verifies tokens using PyJWT"""

    def __init__(self, config: Config):
        self.config: Config = config
        self.jwks_client = jwt.PyJWKClient(self.config.static.auth_jwks_url)

    async def verify(self,
                     security_scopes: SecurityScopes,
                     token: Optional[HTTPAuthorizationCredentials] = Depends(HTTPBearer())) -> str:
        if token is None:
            raise UnauthenticatedException

        # Retrieve the 'kid' from the passed token
        try:
            signing_key = self.jwks_client.get_signing_key_from_jwt(
                token.credentials
            ).key
        except jwt.exceptions.PyJWKClientError as error:
            raise UnauthorizedException(str(error)) from error
        except jwt.exceptions.DecodeError as error:
            raise UnauthorizedException(str(error)) from error

        try:
            payload = jwt.decode(
                token.credentials,
                signing_key,
                algorithms=self.config.static.auth_algorithms,
                audience=self.config.static.auth_api_audience,
                issuer=self.config.static.auth_issuer,
            )
        except Exception as error:
            raise UnauthorizedException(str(error)) from error

        # Check the expiration time
        if datetime.fromtimestamp(payload["exp"]) < datetime.now():
            raise UnauthorizedException("Token has expired")

        # Check issued at time
        if datetime.fromtimestamp(payload["iat"]) >= datetime.now():
            raise UnauthorizedException("Token issued in the future")

        if 'uid' not in payload:
            raise UnauthorizedException("Token does not contain a user ID")

        trace.get_current_span().set_attribute("user_id", payload['uid'])

        return uuid.UUID(payload['uid'])

    async def verify_token(self, token: str) -> str:
        """Verifies a token"""
        return await self.verify(SecurityScopes(),
                                 HTTPAuthorizationCredentials(scheme='Bearer', credentials=token))
