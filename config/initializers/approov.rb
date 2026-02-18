# frozen_string_literal: true

# Fail fast on startup when the required Approov secret is missing/invalid.
ApproovMiddleware.validate_required_secret!
