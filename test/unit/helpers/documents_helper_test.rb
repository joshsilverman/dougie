require 'test_helper'

class DocumentsHelperTest < ActionView::TestCase

  def test_create

    @user = users(:one)
    sign_in @user
#    sign_in :one, @user

    get 'documents/new/1'
  end

end
