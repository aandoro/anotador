from app.schemas.health import HealthStatusResponse
from app.schemas.auth import (
    UserRegisterRequest,
    UserLoginRequest,
    TokenResponse,
    ForgotPasswordRequest,
    ResetPasswordRequest,
    MessageResponse,
)
from app.schemas.user import UserProfileResponse, UserProfileUpdateRequest
from app.schemas.exercise import ExerciseResponse
from app.schemas.personal_record import (
    PersonalRecordCreateRequest,
    PersonalRecordResponse,
)

__all__ = [
    "HealthStatusResponse",
    "UserRegisterRequest",
    "UserLoginRequest",
    "TokenResponse",
    "ForgotPasswordRequest",
    "ResetPasswordRequest",
    "MessageResponse",
    "UserProfileResponse",
    "UserProfileUpdateRequest",
    "ExerciseResponse",
    "PersonalRecordCreateRequest",
    "PersonalRecordResponse",
]
