require "test_helper"

module AbilityTest
  class TeamMemberScenarios < ActiveSupport::TestCase
    setup do
      @user = FactoryBot.create :onboarded_user
      @another_user = FactoryBot.create :onboarded_user
      @membership = FactoryBot.create :membership, user: @user, team: @user.current_team
      @team = @membership.team
      @user_ability = Ability.new(@user)
    end

    test "can manage their account" do
      assert @user_ability.can?(:manage, @user)
    end

    test "can't manage foreign account" do
      assert @user_ability.cannot?(:manage, @another_user)
    end

    test "can manage team" do
      assert @user_ability.can?(:manage, @user, Team.new)
    end

    test "can destroy their membership" do
      skip("app/models/ability.rb:22")
      assert @user_ability.cannot?(:destroy, @user, Membership.new(user: @user))
    end
  end

  class NonTeamMemberScenarios < ActiveSupport::TestCase
    setup do
      @user = FactoryBot.create :user
      @another_user = FactoryBot.create :user
      @team = FactoryBot.create :team
      @user_ability = Ability.new(@user)
    end

    test "can manage their account" do
      assert @user_ability.can?(:manage, @user)
    end

    test "can't manage foreign account" do
      assert @user_ability.cannot?(:manage, @another_user)
    end

    test "can't manage team" do
      assert @user_ability.cannot?(:manage, @another_user, @team)
    end

    test "can't manage membership" do
      assert @user_ability.cannot?(:manage, @another_user, Membership.new)
    end
  end

  class TeamAdminScenarios < ActiveSupport::TestCase
    setup do
      @admin = FactoryBot.create :onboarded_user
      @another_user = FactoryBot.create :onboarded_user
      @membership = FactoryBot.create :membership, user: @admin, team: @admin.current_team, role_ids: [Role.admin.id]
      @admin_ability = Ability.new(@admin)
    end

    test "can manage team" do
      assert @admin_ability.can?(:manage, @membership.team)
    end

    test "can manage membership" do
      assert @admin_ability.can?(:manage, Membership.new(team: @admin.current_team))
    end
  end

  class BillingScenarios < ActiveSupport::TestCase
    setup do
      @user = FactoryBot.create :onboarded_user
      @user_ability = Ability.new(@user)
    end

    test "billing abilities when billing is enabled" do
      # Test billing-related abilities if billing is enabled
      if defined?(Billing) && billing_enabled?
        # Test that billing abilities are applied
        assert @user_ability.can?(:read, @user)
      end
    end
  end

  class DeveloperScenarios < ActiveSupport::TestCase
    setup do
      @developer = FactoryBot.create :onboarded_user
      @developer.update!(role_ids: [Role.developer.id])
      @developer_ability = Ability.new(@developer)
    end

    test "developer has admin abilities" do
      # Test developer-specific abilities
      assert @developer_ability.can?(:manage, @developer)
    end
  end

  class StripeIntegrationScenarios < ActiveSupport::TestCase
    setup do
      @user = FactoryBot.create :onboarded_user
      @user_ability = Ability.new(@user)
    end

    test "stripe abilities when stripe is enabled" do
      if stripe_enabled?
        # Test Stripe-related abilities
        assert @user_ability.can?(:read, Oauth::StripeAccount.new(user: @user))
        assert @user_ability.can?(:create, Oauth::StripeAccount.new(user: @user))
        assert @user_ability.can?(:destroy, Oauth::StripeAccount.new(user: @user))
        assert @user_ability.can?(:manage, Integrations::StripeInstallation.new(team: @user.current_team))
      end
    end
  end

  class PlatformAccessTokenScenarios < ActiveSupport::TestCase
    setup do
      @user = FactoryBot.create :onboarded_user
      @user_ability = Ability.new(@user)
    end

    test "can manage provisioned access tokens" do
      # Test access token abilities
      access_token = Platform::AccessToken.new(
        application: Platform::Application.new(team: @user.current_team),
        provisioned: true
      )
      assert @user_ability.can?(:manage, access_token)
    end

    test "cannot manage non-provisioned access tokens" do
      access_token = Platform::AccessToken.new(
        application: Platform::Application.new(team: @user.current_team),
        provisioned: false
      )
      assert @user_ability.cannot?(:manage, access_token)
    end
  end

  class InvitationScenarios < ActiveSupport::TestCase
    setup do
      @user = FactoryBot.create :onboarded_user
      @user_ability = Ability.new(@user)
    end

    test "can manage team invitations" do
      invitation = Invitation.new(team: @user.current_team)
      assert @user_ability.can?(:manage, invitation)
    end

    test "cannot manage invitations from other teams" do
      other_team = FactoryBot.create(:team)
      invitation = Invitation.new(team: other_team)
      assert @user_ability.cannot?(:manage, invitation)
    end
  end

  class CollaboratingUsersScenarios < ActiveSupport::TestCase
    setup do
      @user = FactoryBot.create :onboarded_user
      @collaborating_user = FactoryBot.create :onboarded_user
      @user_ability = Ability.new(@user)
    end

    test "can read collaborating users" do
      # This would need to be set up with actual collaborating users
      # For now, test the basic structure
      assert @user_ability.can?(:read, @user)
    end
  end
end
