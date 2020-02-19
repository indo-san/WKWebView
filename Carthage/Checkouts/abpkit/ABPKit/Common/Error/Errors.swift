/*
 * This file is part of Adblock Plus <https://adblockplus.org/>,
 * Copyright (C) 2006-present eyeo GmbH
 *
 * Adblock Plus is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * Adblock Plus is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Adblock Plus.  If not, see <http://www.gnu.org/licenses/>.
 */

/// Global custom errors for ABPKit. Numbering starts at zero.
/// These errors should be considered transitional, to serve development of the framework.

/// Error cases for block lists.
/// Cases of ABPFilterListError will eventually be merged here.
/// - badInitiator: Initiator is wrong.
/// - badRulesRaw: Raw rules could not be handled.
/// - failedJSONArrayOpen: JSON array could not be handled.
/// - notFound: Rules could not be located.
/// - ruleCountExceeded: Count is over maximum rules.
public
enum ABPBlockListError: Error {
    case badInitiator
    case badRulesRaw
    case failedJSONArrayOpen
    case notFound
    case ruleCountExceeded
}

/// Parameterized error cases for block lists.
/// - badBlockListSource(BlockListSourceable?): BL source determined to be wrong.
/// - badRule(BlockingRule): Rule has bad data.
/// - notFoundForBL(BlockList?): A BlockList is missing.
public
enum ABPBlockListParameterizedError: Error {
    case badBlockListSource(BlockListSourceable?)
    case badRule(BlockingRule)
    case notFoundForBL(BlockList?)
}

/// Errors specific to ABPKit-Combine.
/// - badTypeCast: Type cast failed.
/// - missingObject: A required object is not available.
public
enum ABPCombineError: Error {
    case badTypeCast
    case missingObject
}

/// Error cases for configuration.
/// - badPlatform: Platform is not valid.
/// - invalidAppGroup: App group is not valid.
/// - invalidBundle: Bundle is not valid.
/// - invalidBundlePrefix: Bundle prefix is not valid.
/// - invalidConfigPlist: Configuration property list cannot be found.
/// - invalidContainerURL: Bad container URL.
/// - unexpectedData: Case is not handled for given data.
public
enum ABPConfigurationError: Error {
    case badPlatform
    case invalidAppGroup
    case invalidBundle
    case invalidBundlePrefix
    case missingConfigPlist
    case invalidContainerURL
    case unexpectedData
}

/// Error cases for managing content blocking.
/// - invalidIdentifier: Invalid ID.
public
enum ABPContentBlockerError: Error {
    case invalidIdentifier
}

/// Error cases for managing device tokens.
/// - invalidEndpoint: Endpoint URL was not found.
public
enum ABPDeviceTokenSaveError: Error {
    case invalidEndpoint
}

/// Error cases for download tasks.
/// - badContainerURL: Container URL is not valid.
/// - badDestinationURL: Bad destination URL for a file operation.
/// - badFilename: Bad filename for filter list rules.
/// - badFilterListModel: Bad model object.
/// - badFilterListModelName: Bad name for model object.
/// - badSourceDownload: SourceDownload corresponding to the task could not be identified.
/// - badSourceURL: URL is invalid.
/// - failedCopy: Failure during copy operation.
/// - failedFilterListModelSave: Failed to save model object.
/// - failedMove: Failure during file move operation.
/// - failedRemoval: Failure during file remove operation.
/// - failedToMakeBackgroundSession: Failed during background session creation.
/// - failedToMakeDownloadTask: Download task could not be created for the download.
/// - failedToUpdateUserDownloads: Downloads could not be updated.
/// - invalidResponse: Web server response was invalid.
/// - tooManyRequests: HTTP connection failed due to temporary state.
public
enum ABPDownloadTaskError: Error {
    case badContainerURL
    case badDestinationURL
    case badFilename
    case badFilterListModel
    case badFilterListModelName
    case badSourceDownload
    case badSourceURL
    case failedCopy
    case failedFilterListModelSave
    case failedMove
    case failedRemoval
    case failedToMakeBackgroundSession
    case failedToMakeDownloadTask
    case failedToUpdateUserDownloads
    case invalidResponse
    case tooManyRequests
}

/// Parameterized error cases for download tasks.
/// - notComplete(SourceDownload): Incomplete source download.
/// - invalidResponse(URLResponse?, BlockListSourceable?): Download failed.
public
enum ABPDownloadTaskParameterizedError: Error {
    case notComplete(SourceDownload)
    case invalidResponse(URLResponse?, BlockListSourceable?)
}

/// Dummy errors used for development.
/// - workInProgress: Indicates WIP, not intended for production use.
public
enum ABPDummyError: Error {
    case workInProgress
}

/// Error cases for filter list processing.
/// - aaStateMismatch: Acceptable ads state is mismatched.
/// - ambiguousModels: Model objects are not unique or are missing.
/// - badContainer: Container could not be accessed.
/// - badSource: BlockList source is invalid.
/// - failedDecoding: Could not decode a list.
/// - failedEncodeRule: A rule could not be encoded.
/// - failedRemoveModels: Failed to remove model(s).
/// - invalidData: Data could not be read from the list.
/// - jsonArrayNotDetected: Could not find termination of JSON array.
/// - missingName: Name could not be read.
/// - missingRules: Rules could not be read.
/// - notFound: Count not find a matching filter list.
public
enum ABPFilterListError: Error {
    case aaStateMismatch
    case ambiguousModels
    case badContainer
    case badSource
    case failedDecoding
    case failedEncodeRule
    case failedRemoveModels
    case invalidData
    case jsonArrayNotDetected
    case missingName
    case missingRules
    case notFound
}

/// Error cases related to mutable state.
/// - ambiguousModels: Model objects are not unique or are missing.
/// - badEnumerator: Failed to obtain enumerator.
/// - badState: Encountered invalid state.
/// - invalidData: Indicates error with data.
/// - invalidType: Indicates error with a type.
/// - missingDefaults: UserDefaults not found.
public
enum ABPMutableStateError: Error {
    case ambiguousModels
    case badEnumerator
    case badState
    case invalidData
    case invalidType
    case missingDefaults
}

/// Error cases for the user model.
/// - badDataUser: Data for user is invalid.
/// - badDownloads: Download data is invalid.
/// - failedUpdateData: Internal data update failed.
/// - userBlockListNotFound: Missing a block list.
public
enum ABPUserModelError: Error {
    case badDataUser
    case badDownloads
    case failedUpdateData
    case userBlockListNotFound
}

/// Error cases for the web blocker.
/// - badURL: URL is invalid.
/// - missingUserContentController: Expected WKUserContentController not found.
public
enum ABPWebViewBlockerError: Error {
    case badURL
    case missingUserContentController
}

/// Error cases for the rule store.
/// - invalidRuleData: Bad/missing data.
/// - missingRuleList: Rule list not found.
public
enum ABPWKRuleStoreError: Error {
    case invalidRuleData
    case missingRuleList
}

/// Error cases related to schedulers.
/// - notOnMain: Not running on main thread, as required.
public
enum ABPSchedulerError: Error {
    case notOnMain
}

// ------------------------------------------------------------
// MARK: - Testing -
// ------------------------------------------------------------

/// Custom errors for ABPKit tests.

/// Error cases for download tasks.
/// - invalidData: Unable to obtain valid data.
public
enum ABPKitTestingError: Error {
    case invalidData
}
