Feature: Devices

  Background: There are some devices
    Given I am signed in as a user
      And I click "Dashboard"
      And I click "Devices"
      And there's a device in the database with the UUID "123456789123"

    @wip
    Scenario: User adds and views a device
      Given I click "Add new device"
        And I enter UUID "123456789123" and a friendly name "G-RALA"
      When I click "Search"
      Then I should see "This device has been bound to your account!"
        And I should see "G-RALA"
      When I click "G-RALA"
        Then I should see "G-RALA"
      When I click "Delete device"
        Then I should see "Device deleted"
        Then I should not see "G-RALA"