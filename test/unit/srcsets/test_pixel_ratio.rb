require_relative 'test_helper_srcsets'

class TestSrcsetPixelRatio < Minitest::Test
  include TestHelperSrcset
  def setup
    build_source_stub
    build_genstubs

    PictureTag.stubs(preset: {
                       'pixel_ratios' => [1, 1.5, 2, 3],
                       'base_width' => 100
                     })

    @tested = Srcsets::PixelRatio.new(@source_image, 'original')
  end

  def test_basic
    correct =
      '/img-100-aaaaa.jpg 1.0x, ' \
      '/img-150-aaaaa.jpg 1.5x, ' \
      '/img-200-aaaaa.jpg 2.0x, ' \
      '/img-300-aaaaa.jpg 3.0x'

    assert_equal correct, @tested.to_s
  end
end
