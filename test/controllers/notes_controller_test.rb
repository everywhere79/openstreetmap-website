require "test_helper"

class NotesControllerTest < ActionDispatch::IntegrationTest
  def setup
    super
    # Stub nominatim response for note locations
    stub_request(:get, %r{^https://nominatim\.openstreetmap\.org/reverse\?})
      .to_return(:status => 404)
  end

  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/user/username/notes", :method => :get },
      { :controller => "notes", :action => "index", :display_name => "username" }
    )
  end

  def test_index_success
    first_user = create(:user)
    second_user = create(:user)
    moderator_user = create(:moderator_user)

    create(:note) do |note|
      create(:note_comment, :note => note, :author => first_user)
    end
    create(:note) do |note|
      create(:note_comment, :note => note, :author => second_user)
    end
    create(:note, :status => "hidden") do |note|
      create(:note_comment, :note => note, :author => second_user)
    end

    # Note that the table rows include a header row
    get user_notes_path(:display_name => first_user.display_name)
    assert_response :success
    assert_select "table.note_list tr", :count => 2

    get user_notes_path(:display_name => second_user.display_name)
    assert_response :success
    assert_select "table.note_list tr", :count => 2

    get user_notes_path(:display_name => "non-existent")
    assert_response :not_found

    session_for(moderator_user)

    get user_notes_path(:display_name => first_user.display_name)
    assert_response :success
    assert_select "table.note_list tr", :count => 2

    get user_notes_path(:display_name => second_user.display_name)
    assert_response :success
    assert_select "table.note_list tr", :count => 3

    get user_notes_path(:display_name => "non-existent")
    assert_response :not_found
  end

  def test_index_paged
    user = create(:user)

    create_list(:note, 50) do |note|
      create(:note_comment, :note => note, :author => user)
    end

    get user_notes_path(:display_name => user.display_name)
    assert_response :success
    assert_select "table.note_list tr", :count => 11

    get user_notes_path(:display_name => user.display_name, :page => 2)
    assert_response :success
    assert_select "table.note_list tr", :count => 11
  end
end
