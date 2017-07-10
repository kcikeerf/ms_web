module SwtkErrors
 class NotFoundError < StandardError;end
 class SavePaperHasError < StandardError;end
 class ParameterInvalidError < StandardError;end
 class UserExistedError < StandardError;end
 class SaveOnlineTestError < StandardError;end
 class TestTenantNotAssociatedError < StandardError;end
 class DeletePaperError < StandardError; end
 class LockResourceFailed < StandardError; end
 class ReleaseResourceLockFailed < StandardError; end
 class CannotLockALockingResource < StandardError; end
 class ExclusiveLocking < StandardError; end
 class ShareLocking < StandardError; end
end
