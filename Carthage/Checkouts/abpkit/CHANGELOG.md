# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.0] - 2020-02-14
### Added
- Allowed configuration of query parameters for partner integrations. ABPKit-Configuration.plist
  has been relocated to the the root path for the project. The following fields are customizable:
  - addonName
  - partnerApplication
  - partnerApplicationVersion
-  Fixed testing of periodic downloads
  - Previous modification of the periodic update divisor (#632) led to failure of
    testPeriodicDownloads(). Separate configurability of that value has been added to fix the test.
- Explicit completion handling when moving downloaded files to their final destination.    
- A UI tester, for the demo host apps, that rapidly changes available states while invoking all associated processing. It
  is not intended for general use. It can be enabled on the host app targets with the following build setting:
  - OTHER_SWIFT_FLAGS = "-DABP_AUTO_TESTER_FAIL_ON_ERR -DABP_AUTO_TESTER_TABS -DABP_AUTO_TESTER_AA"; 
  
### Changed
- Updated selector and image used to indicate that AA is deselected in host apps.
- Increased periodic update check frequency to 20 s intervals
  - The previous value corresponding to 3 hrs was found to be insufficient to have
    the Updater download updates for expired block lists under integrations on iOS.
- Separated Updater and User states while fixing some related problems. The Updater should not mutate User states.
- Rule handling has been further refined and verified. Some extra re-compilation of rules that exist in the rule store has been prevented.
- Automatic update handling has received the following changes:
  - If an error other than a file remove failure occurs during automatic updates,
    the automatic updater will stop running for the remainder of the app's lifetime.
    - This accounts for the unlikely event that an untested error occurs prior
      to having an error handling procedure that can handle general errors.
  - All known errors, up to this point, are being accounted for and cessation of updates is considered unlikely under production usage scenarios.
- Refactored rules helping operations while separating legacy usages.
  - Implemented a RulesOperable protocol to support rule handling for User.
  - Removed a custom bundle argument that was propagated through rule processing but doesn't apply to the production operation chain.
- Updated RxSwift to 5.0.1.  
- Updated the projects for Xcode 11.x.
  - Note: There was a build warning indicating that the new build system is recommended. There
    are still incompatibility issues the new build system and Carthage builds. The warning does not
    have a setting in build settings but can be disabled successfully by selecting the
    new build system and then changing it back. It should not further appear after this procedure.
- Explicitly disabled Mac Catalyst support for iOS targets.
  - Support for Mac Catalyst is not provided at this time.
- Updated host app bundle IDs due to losing the previous values due to aberrant activity on the company's development account.
- Normalized usages of return as a statement and as a documentation parameter.

#### Legacy code
  - Separated legacy download events and persistence operations.
  - Labeled/Removed more legacy items (mutable state and filter list model).

#### Combine
  - Renamed some groups and bundle IDs for consistency with the naming scheme used to identify ABPKit-Combine going forward. 
  - Added Combine extensions for v[1,2] block list parsers.
  - Initiated a common mapping of type aliases between Observables and Publishers (see ObservableAliases.swift and PublisherAliases.swift).
  - Some manual DisposeBag handling has been added. This allows greater code sharing with ABPKit-Combine.
  - Note that support for Combine is still a work-in-progress.
    
### Removed
- All usages of RxCocoa. ABPKit currently has no reliance on KVO or BehaviorRelay (RxRelay or RxCocoa).

### Fixed
 Improved manual DisposeBag handling including the following items:
  - Reduced possibility of nil references under correct usage of the interface in Bags.
  - Decrease the chance for programmer error during manual handling.
- Prevented simultaneous access errors on the global dispose bag for the Updater
  - This condition was affecting removal of the dispose bag during testing only.      
- Prevented unowned references during unexpected deallocations of web views.
  - A custom bundle parameter has been propagated throughout the rule processing operations for the following reasons:
    - Easier testing of procedures involving blocking rules.
    - Future support of bundled block lists.
- Cleared downloads to set the initial state in testDownloadMultiple().    
- Some problems occurring during useContentBlocking() including:
  - Handling of failures to remove rules (WKError 8). It has been explicitly made allowable.
  - Conditions where JSON source would be missing due to history sync during updates by automatic downloads.
  - Obtaining a matching fallback block list if it is available during a rule list adding failure. 
    - Note that switching AA states without waiting for completion of a previous switch, considered a programmer error, can cause a fallback list to be used, if available.        
- The RxSwift version in the optional binary Cartfile.

## [0.3.0] - 2019-08-03
### Added
- Automatic periodic user block list updates.
  - This includes **breaking changes** to the User model. Overwriting user state with `User().save()` is sufficient to update any saved instance. However, whitelisted hostnames and block list settings should be taken into account when generating a new state for existing users.
  - Downloads are set to happen approximately 24 hours after the last download when a host app is in the foreground.
  - Newly downloaded block lists are activated on the next user action when a download is available.
- A global download counter. It transmits a value for analytics in a way designed to protect user privacy.
- A whitelisted hostname to the demo host apps. This is for tracking its state during testing.

### Changed
- BlockList downloading. Only the user's active AA state is downloaded.
  - Previously, downloads for all states were being retrieved.
  - If a user changes the AA state and a matching block list has already been downloaded, a new download will not happen.
- BlockList model. It has a new `initiator` property for the purpose of distinguishing automatic downloads.
- Project readme to include more details about user state handling.

### Fixed
- Status message display in host apps. With all of the downloading changes in this release, the status message should now be shown whenever the host apps switch to a newly downloaded block list.

## [0.2.1] - 2019-06-21
### Fixed
- A few code errors that were present when compiling without the Swift flag `ABPDEBUG`.
- The source of rules for the host app content blocker extensions. Default block lists are now available from `HostCBExt-common/Resources`.

## [0.2.0] - 2019-06-06
### Added
- A special content blocking rule for debug builds intended to more clearly demonstrate correct operations.
- Tab views in the demo apps to demonstrate handling of multiple web views.
- Configuration, by a property list, for bundled block lists. They are not included by default.
- Configuration, by a property list, for app groups capable of being read outside of the framework. This file defaults to being read from the host app.

### Changed
- Swift version to 5.0.1 including minor code changes as a result.
- Rules processing to now default to loading raw JSON rules. Additional validation is performed if the initial loading fails.
- The project structure. It is now organized under an Xcode workspace, to better support usage by external developers. Code signing requirements were removed for the framework and the demo apps were placed in a separate project.
- Loading of rules in the WebKit rule store. Only the active content blocking rules are loaded. Previously, inactive rules were attempted to be cached in the store but this proved to be unviable.

### Removed
- Default bundled block lists. They are no longer shipped with ABPKit. They are instead downloaded on demand.

### Fixed
- Main thread usage during processing of content blocking rules. Operations are now executed on a separate background operation queue.
- Main thread usage during downloading. Operations are now executed on a separate background operation queue.
- Memory leaks related to `UserBlockListDownloader`. The download session is invalidated when needed.
- Some extraneous operations during rule list processing. They have been eliminated.
- Whitelist handling. It has been revised and tested against all rule list processing changes.

## [0.1.0] - 2018-12-16
### Added
- Initial release. Supports content blocking in WKWebView on iOS and macOS.
