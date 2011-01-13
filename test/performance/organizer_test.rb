require 'test_helper'
require 'rails/performance_test_help'

class OrganizerTest < ActionDispatch::PerformanceTest

  def test_organizer

    ###################
    # [370] (Baseline)

    # login via https
    https!
    get "/users/sign_out"
    get "/users/sign_in"
    assert_response :success
    post_via_redirect "/users/sign_in", { 'user[email]' => users(:one).email, 'user[password]' => 'aaaaaa'}
    assert_equal '/', path

    # organizer
    get_via_redirect "/"

  end

end
