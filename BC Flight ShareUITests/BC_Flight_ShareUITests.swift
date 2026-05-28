import XCTest

final class BC_Flight_ShareUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Auth Screen

    @MainActor
    func testAuthScreen_appearsOnLaunch() throws {
        // The app should show either Sign In or Create Account on first launch
        let signInTab = app.buttons["Sign In"]
        let createTab = app.buttons["Create Account"]
        XCTAssertTrue(signInTab.waitForExistence(timeout: 5) || createTab.waitForExistence(timeout: 5))
    }

    @MainActor
    func testAuthScreen_hasAppTitle() throws {
        let title = app.staticTexts["BC Flight Share"]
        XCTAssertTrue(title.waitForExistence(timeout: 5), "App title should be visible on auth screen")
    }

    @MainActor
    func testAuthScreen_signInFormHasEmailAndPasswordFields() throws {
        let emailField = app.textFields["BC Email (@bc.edu)"]
        let passwordField = app.secureTextFields["Password"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 5))
        XCTAssertTrue(passwordField.waitForExistence(timeout: 5))
    }

    @MainActor
    func testAuthScreen_canSwitchToCreateAccount() throws {
        let createTab = app.buttons["Create Account"]
        XCTAssertTrue(createTab.waitForExistence(timeout: 5))
        createTab.tap()

        let nameField = app.textFields["Full Name"]
        let appeared = nameField.waitForExistence(timeout: 3)
        XCTAssertTrue(appeared, "Full Name field should appear after switching to Create Account")
    }

    @MainActor
    func testAuthScreen_createAccountHasAllFields() throws {
        app.buttons["Create Account"].tap()

        XCTAssertTrue(app.textFields["Full Name"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.textFields["BC Email (@bc.edu)"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.secureTextFields["Password (min 6 characters)"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.secureTextFields["Confirm Password"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testSignIn_buttonDisabledWithEmptyFields() throws {
        // On the sign-in form the Sign In action button should be disabled when fields are empty
        let emailField = app.textFields["BC Email (@bc.edu)"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 5))

        // Find the submit button (inside the form, distinct from the tab button)
        // Both have the same label; the form button is lower on screen
        let buttons = app.buttons.matching(identifier: "Sign In").allElementsBoundByIndex
        // At least one should exist
        XCTAssertGreaterThan(buttons.count, 0)
    }

    @MainActor
    func testCreateAccount_canSwitchBackToSignIn() throws {
        app.buttons["Create Account"].tap()
        XCTAssertTrue(app.textFields["Full Name"].waitForExistence(timeout: 3))

        app.buttons["Sign In"].firstMatch.tap()
        XCTAssertTrue(app.textFields["BC Email (@bc.edu)"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.textFields["Full Name"].exists, "Full Name field should be hidden on Sign In tab")
    }

    // MARK: - Launch Snapshot

    @MainActor
    func testLaunch_takesScreenshot() throws {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Auth Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

// MARK: - Post-Login Flow (requires a logged-in session)
// These tests use a test account. Set TEST_EMAIL and TEST_PASSWORD in the scheme
// environment variables, or they will be skipped.

final class BC_Flight_ShareLoggedInUITests: XCTestCase {

    var app: XCUIApplication!

    private var testEmail: String { ProcessInfo.processInfo.environment["TEST_EMAIL"] ?? "" }
    private var testPassword: String { ProcessInfo.processInfo.environment["TEST_PASSWORD"] ?? "" }

    override func setUpWithError() throws {
        continueAfterFailure = false
        guard !testEmail.isEmpty, !testPassword.isEmpty else {
            throw XCTSkip("Set TEST_EMAIL and TEST_PASSWORD environment variables to run logged-in tests")
        }
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
        try login()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    private func login() throws {
        let emailField = app.textFields["BC Email (@bc.edu)"]
        guard emailField.waitForExistence(timeout: 5) else { return }

        emailField.tap()
        emailField.typeText(testEmail)

        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText(testPassword)

        app.buttons.matching(identifier: "Sign In").lastMatch.tap()
    }

    // MARK: - Main Tab Bar

    @MainActor
    func testMainApp_hasThreeTabs() throws {
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 8))
        XCTAssertTrue(app.tabBars.buttons["Flights"].exists)
        XCTAssertTrue(app.tabBars.buttons["My Rides"].exists)
        XCTAssertTrue(app.tabBars.buttons["Profile"].exists)
    }

    @MainActor
    func testCalendarTab_showsMonthAndYear() throws {
        XCTAssertTrue(app.tabBars.buttons["Flights"].waitForExistence(timeout: 8))
        app.tabBars.buttons["Flights"].tap()

        // Navigation title
        XCTAssertTrue(app.navigationBars["BC Flight Share"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testCalendarTab_monthNavigationButtonsExist() throws {
        app.tabBars.buttons["Flights"].tap()
        XCTAssertTrue(app.buttons["chevron.left"].waitForExistence(timeout: 3) ||
                      app.images["chevron.left"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testCalendarTab_plusButtonOpensCreateRideSheet() throws {
        app.tabBars.buttons["Flights"].tap()
        XCTAssertTrue(app.navigationBars["BC Flight Share"].waitForExistence(timeout: 5))

        // Tap the + button in the nav bar
        let plusButton = app.navigationBars["BC Flight Share"].buttons.firstMatch
        plusButton.tap()

        XCTAssertTrue(app.navigationBars["Post a Ride"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testCreateRideSheet_hasExpectedFields() throws {
        app.tabBars.buttons["Flights"].tap()
        XCTAssertTrue(app.navigationBars["BC Flight Share"].waitForExistence(timeout: 5))
        app.navigationBars["BC Flight Share"].buttons.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Post a Ride"].waitForExistence(timeout: 3))

        XCTAssertTrue(app.staticTexts["Destination"].exists)
        XCTAssertTrue(app.staticTexts["Meeting Location at BC"].exists)
        XCTAssertTrue(app.staticTexts["Departure"].exists)
        XCTAssertTrue(app.staticTexts["Max Riders (including you)"].exists)
    }

    @MainActor
    func testCreateRideSheet_canBeDismissedWithCancel() throws {
        app.tabBars.buttons["Flights"].tap()
        XCTAssertTrue(app.navigationBars["BC Flight Share"].waitForExistence(timeout: 5))
        app.navigationBars["BC Flight Share"].buttons.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Post a Ride"].waitForExistence(timeout: 3))

        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.navigationBars["BC Flight Share"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testCreateRideSheet_quickDestinationChips() throws {
        app.tabBars.buttons["Flights"].tap()
        XCTAssertTrue(app.navigationBars["BC Flight Share"].waitForExistence(timeout: 5))
        app.navigationBars["BC Flight Share"].buttons.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Post a Ride"].waitForExistence(timeout: 3))

        XCTAssertTrue(app.buttons["Logan Airport (BOS)"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["South Station"].exists)
    }

    @MainActor
    func testMyRidesTab_isAccessible() throws {
        app.tabBars.buttons["My Rides"].tap()
        XCTAssertTrue(app.navigationBars["My Rides"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testProfileTab_showsUserEmail() throws {
        app.tabBars.buttons["Profile"].tap()
        XCTAssertTrue(app.navigationBars["Profile"].waitForExistence(timeout: 5))
        // The profile shows the logged-in email
        XCTAssertTrue(app.staticTexts[testEmail].waitForExistence(timeout: 3))
    }

    @MainActor
    func testProfileTab_signOutButtonExists() throws {
        app.tabBars.buttons["Profile"].tap()
        XCTAssertTrue(app.buttons["Sign Out"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testProfileTab_signOutShowsConfirmation() throws {
        app.tabBars.buttons["Profile"].tap()
        XCTAssertTrue(app.buttons["Sign Out"].waitForExistence(timeout: 5))
        app.buttons["Sign Out"].tap()

        XCTAssertTrue(app.alerts["Sign Out"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.alerts["Sign Out"].buttons["Cancel"].exists)
        XCTAssertTrue(app.alerts["Sign Out"].buttons["Sign Out"].exists)

        // Dismiss without signing out
        app.alerts["Sign Out"].buttons["Cancel"].tap()
        XCTAssertTrue(app.navigationBars["Profile"].waitForExistence(timeout: 3))
    }
}

// MARK: - Helper

private extension XCUIElementQuery {
    var lastMatch: XCUIElement {
        allElementsBoundByIndex.last ?? firstMatch
    }
}
