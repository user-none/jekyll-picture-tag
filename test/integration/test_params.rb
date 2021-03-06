require_relative './test_integration_helper'

# This is for testing various tag params. It pulls in presets to make sure
# they're checked correctly, but it's focused on tag arguments.
class TestIntegrationParams < Minitest::Test
  include TestIntegrationHelper

  def setup
    base_stubs
  end

  def teardown
    cleanup_files
  end

  # Basic functionality test, default settings
  def test_defaults
    output = tested
    assert output.errors.empty?

    img = output.at_css('img')

    assert_equal rms_url, img['src']
    assert_equal std_rms_ss, img['srcset']
    assert File.exist? rms_filename
  end

  # Make sure it doesn't overwrite existing files
  def test_with_existing
    FileUtils.mkdir_p '/tmp/jpt/generated'
    @widths.each { |w| FileUtils.touch rms_filename(width: w) }

    MiniMagick::Image.any_instance.expects(:write).never

    tested
  end

  def test_attributes
    params = <<~HEREDOC
      auto rms.jpg class="implicit" --parent class="parent" --picture
       data-awesomeness="11" --img class="img" --source class="source"
       --alt Alternate Text
    HEREDOC

    output = tested(params)
    assert errors_ok? output

    pic = output.at_css('picture')
    img = output.at_css('img')
    sources = output.css('source')

    assert_equal 'parent', pic['class']
    assert_equal '11', pic['data-awesomeness']
    assert_equal 'Alternate Text', img['alt']
    assert img['class'].include? 'implicit'
    assert img['class'].include? 'img'
    assert(sources.all? { |s| s['class'] == 'source' })
  end

  # Make sure attributes don't stick around between multiple instances
  def test_arg_persistence
    tested 'rms.jpg --img class="goaway"'

    assert_nil tested.at_css('img')['class']
  end

  # Make sure corrected widths don't persist
  def test_width_persistence
    tested 'too_large rms.jpg'

    tested 'too_large spx.jpg'
    assert @stderr.include? 'spx.jpg'
  end

  def test_link
    output = tested 'rms.jpg --link example.com'

    refute output.errors.any?
    assert_equal 'example.com', output.at_css('a')['href']
    assert output.at_css('a').children.include? output.at_css('img')
  end

  # Test an image with a space in it
  def test_escaped_whitespace
    output = tested('rms\ with\ space.jpg')
    assert output.errors.empty?

    img = output.at_css('img')
    src = '/generated/rms%20with%20space-100-46a48b.jpg'
    ss = '/generated/rms%20with%20space-25-46a48b.jpg 25w,' \
      ' /generated/rms%20with%20space-50-46a48b.jpg 50w,' \
      ' /generated/rms%20with%20space-100-46a48b.jpg 100w'

    assert_equal src, img['src']
    assert_equal ss, img['srcset']
    assert File.exist? '/tmp/jpt/generated/rms with space-100-46a48b.jpg'
  end

  def test_quoted_whitespace
    output = tested('"rms with space.jpg"')
    assert output.errors.empty?

    img = output.at_css('img')
    src = '/generated/rms%20with%20space-100-46a48b.jpg'
    ss = '/generated/rms%20with%20space-25-46a48b.jpg 25w,' \
      ' /generated/rms%20with%20space-50-46a48b.jpg 50w,' \
      ' /generated/rms%20with%20space-100-46a48b.jpg 100w'

    assert_equal src, img['src']
    assert_equal ss, img['srcset']
    assert File.exist? '/tmp/jpt/generated/rms with space-100-46a48b.jpg'
  end
end
