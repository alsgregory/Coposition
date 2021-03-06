require 'rails_helper'

RSpec.describe Users::ApprovalsController, type: :controller do
  include ControllerMacros

  let(:user) do
    user = create_user
    user.devices << FactoryGirl.create(:device)
    user
  end
  let(:friend) { FactoryGirl.create :user }
  let(:developer) { FactoryGirl.create :developer }
  let(:approval) do
    app = FactoryGirl.create :approval
    app.update(user: user)
    app.save
    app
  end
  let(:approval_two) do
    app = FactoryGirl.create :approval
    app.update(user: friend)
    app.save
    app
  end
  let(:user_params) { { user_id: user.id } }
  let(:friend_approval_create_params) do
    user_params.merge(approval: { approvable: friend.email, approvable_type: 'User' })
  end
  let(:approve_reject_params) { user_params.merge(id: approval.id) }
  let(:invite_params) do
    user_params.merge(invite: '', approval: { approvable: 'new@email.com', approvable_type: 'User' })
  end

  describe 'GET #new' do
    it 'should assign an empty approval' do
      get :new, user_params
      expect((assigns :approval).model_name).to match 'Approval'
    end
  end

  describe 'POST #create' do
    context 'when adding a friend' do
      it 'should create a pending approval, friend request and send an email' do
        count = ActionMailer::Base.deliveries.count
        post :create, friend_approval_create_params
        expect(ActionMailer::Base.deliveries.count).to be(count + 1)
        expect(Approval.count).to eq 2
        expect(Approval.first.user).to eq user
        expect(Approval.first.approvable_id).to eq friend.id
        expect(Approval.first.status).to eq 'pending'
        expect(Approval.last.status).to eq 'requested'
      end

      it 'should confirm an existing user friend request' do
        approval.update(status: 'requested', approvable_id: friend.id, approvable_type: 'User')
        approval_two.update(status: 'pending', approvable_id: user.id, approvable_type: 'User')
        post :create, friend_approval_create_params
        expect(Approval.count).to eq 2
        expect(Approval.first.user).to eq user
        expect(Approval.first.approvable_id).to eq friend.id
        expect(Approval.first.status).to eq 'accepted'
        expect(Approval.last.status).to eq 'accepted'
      end
    end

    context 'when an incorrect name is provided' do
      it 'should not create or approve an approval if trying to add self' do
        friend_approval_create_params[:approval][:approvable] = user.email
        post :create, friend_approval_create_params
        expect(flash[:alert]).to match 'Adding self'
        expect(Approval.count).to eq 0
      end

      it 'should not create/approve if trying to add an exisiting friend' do
        approval.update(status: 'accepted', approvable_id: friend.id, approvable_type: 'User')
        approval_two.update(status: 'accepted', approvable_id: user.id, approvable_type: 'User')
        post :create, friend_approval_create_params
        expect(flash[:alert]).to match 'exists'
        expect(Approval.count).to eq 2
      end
    end

    context 'when inviting a user' do
      it 'should send an email to the address provided' do
        count = ActionMailer::Base.deliveries.count
        post :create, invite_params
        expect(ActionMailer::Base.deliveries.count).to be(count + 1)
      end
    end
  end

  describe 'GET #apps' do
    it 'should assign current users apps, devices, pending' do
      approval.update(status: 'accepted', approvable_id: developer.id, approvable_type: 'Developer')
      get :apps, user_params
      expect(assigns(:presenter).approved).to eq user.developers
      expect(assigns(:presenter).devices).to eq user.devices
      expect(assigns(:presenter).pending).to eq user.developer_requests
    end
  end

  describe 'GET #friends' do
    it 'should assign current users friends' do
      approval_two.update(user: user, status: 'accepted', approvable_id: friend.id, approvable_type: 'User')
      get :friends, user_params
      expect(assigns(:presenter).pending).to eq user.friend_requests
      expect(assigns(:presenter).approved).to eq user.friends
      expect(assigns(:presenter).devices).to eq user.devices
    end
  end

  describe 'POST #approve' do
    it 'should approve a developer approval request' do
      approval.update(status: 'developer-requested', approvable_id: developer.id, approvable_type: 'Developer')
      request.accept = 'text/javascript'
      post :approve, approve_reject_params
      expect(Approval.last.status).to eq 'accepted'
    end
  end

  describe 'POST #reject' do
    it 'should reject and destroy a developer approval request' do
      approval.update(status: 'developer-requested', approvable_id: developer.id, approvable_type: 'Developer')
      expect(Approval.count).to eq 1
      request.accept = 'text/javascript'
      post :reject, approve_reject_params
      expect(Approval.count).to eq 0
    end

    it 'should reject and destroy both sides of a user approval' do
      approval.update(status: 'requested', approvable_id: friend.id, approvable_type: 'User')
      approval_two.update(status: 'pending', approvable_id: user.id, approvable_type: 'User')
      expect(Approval.count).to eq 2
      request.accept = 'text/javascript'
      post :reject, approve_reject_params
      expect(Approval.count).to eq 0
    end

    it 'should destroy an existing approval and permissions' do
      approval.update(status: 'developer-requested', approvable_id: developer.id, approvable_type: 'Developer')
      approval.approve!
      expect(Permission.count).to eq 1
      request.accept = 'text/javascript'
      post :reject, approve_reject_params
      expect(Permission.count).to eq 0
      expect(Approval.count).to eq 0
    end
  end
end
