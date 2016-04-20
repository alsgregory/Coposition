require "rails_helper"

RSpec.describe DevicesHelper, :type => :helper do
  let(:safebuffer) { ActiveSupport::SafeBuffer }
  let(:user) { FactoryGirl::create(:user) }
  let(:developer) { FactoryGirl::create(:developer) }
  let(:permission) {
    device = FactoryGirl::create(:device, user_id: user.id)
    device.developers << developer
    Permission.last
  }

  describe '#permissible_title' do
    it 'should accept either a user or a developer' do
      expect { helper.permissible_title(user) }.not_to raise_error
      expect { helper.permissible_title(developer) }.not_to raise_error
    end

    it "should return html with the user's email if it's a user" do
      expect( helper.permissible_title(user) ).to match(user.email)
      expect( helper.permissible_title(user).class ).to eq(safebuffer)
    end

    it "should return html with the company name if it's a developer" do
      expect( helper.permissible_title(developer).class ).to eq(safebuffer)
      expect( helper.permissible_title(developer) ).to match(ERB::Util::h(developer.company_name))
    end
  end

  describe '#permissions_control_class' do
    it 'should return the string "master-switches" if permissionable is not a Permission' do
      expect( helper.permissions_control_class(developer).class ).to eq(String)
      expect( helper.permissions_control_class(developer) ).to include('master')
    end
  end

  describe '#permissions_switch_class' do
    it 'should return a different string depending on whether permissible is a Permission or not' do
      expect( helper.permissions_switch_class(permission) ).to include('permission')
      expect( helper.permissions_switch_class(developer) ).to include('master')
    end
  end

  describe '#permissions_check_box_value' do
    it 'should return a boolean value depending on if permissionable is a Permission depending on the type' do
      permission.update(privilege: 'disallowed', bypass_delay: false, bypass_fogging: true)
      expect( helper.permissions_check_box_value(permission, 'disallowed')).to eq true
      expect( helper.permissions_check_box_value(permission, 'last_only')).to eq false
      expect( helper.permissions_check_box_value(permission, 'bypass_delay')).to eq false
      expect( helper.permissions_check_box_value(permission, 'bypass_fogging')).to eq true
    end
  end

  describe '#permissions_for_all' do
    it 'should return the string "for all" if permissionable is not a Permission' do
      expect( helper.permissions_for_all(user).class ).to eq(String)
      expect( helper.permissions_for_all(user) ).to match('for all')
    end
  end
end
