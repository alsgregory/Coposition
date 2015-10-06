Given(/^there's a device in the database with the UUID "(.*?)"$/) do |uuid|
  dev = FactoryGirl::create :device
  dev.uuid = uuid
  dev.save!
end

Given(/^I enter UUID "(.*?)" and a friendly name "(.*?)"$/) do |uuid, name|
  fill_in "device[uuid]", with: uuid
  fill_in "device[name]", with: name
end