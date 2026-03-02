from typing import Final



from enum import Enum

CACHE_KEY: Final = "cache.key"
"""
The key identifying the cache entry.
"""

CACHE_MISS: Final = "cache.miss"
"""
Indicates whether the cache operation resulted in a cache miss.
"""

CACHE_OPERATION_NAME: Final = "cache.operation.name"
"""
The name of the cache operation.
"""

CACHE_TTL: Final = "cache.ttl"
"""
Time-to-live of the cache entry in seconds.
"""



class CacheOperationNameValues(Enum):
    GET = "get"
    """Get a value from the cache."""
    SET = "set"
    """Set a value in the cache."""
    DELETE = "delete"
    """Delete a value from the cache."""
