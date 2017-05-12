module SwtkErrors
 class NotFoundError < StandardError;end
 class SavePaperHasError < StandardError;end
 class ParameterInvalidError < StandardError;end
 class UserExistedError < StandardError;end
 class SaveOnlineTestError < StandardError;end
 class TestTenantNotAssociatedError < StandardError;end
 class DeletePaperError < StandardError; end
end
