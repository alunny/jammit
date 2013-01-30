$: << File.expand_path(File.dirname(__FILE__) + "/..") ; require 'test_helper'
require 'zlib'

class CommandLineTest < Test::Unit::TestCase
  JAMMIT = "bundle exec bin/jammit"

  def setup
    ENV['RAILS_ROOT'] = 'test'
  end

  def teardown
    begin
      FileUtils.rm_r('test/precache')
    rescue Errno::ENOENT
    end
  end

  def test_version_and_help_can_run
    assert system("#{ JAMMIT } -v > /dev/null")
    assert system("#{ JAMMIT } -h > /dev/null")
  end

  def test_jammit_precaching
    system("#{ JAMMIT } -c test/config/assets.yml -o test/precache -u http://www.example.com")
    assert_equal PRECACHED_FILES, glob('test/precache/*')

    assert_equal zlib_read('test/precache/css_test-datauri.css.gz'),
      File.read('test/fixtures/jammed/css_test-datauri.css')

    assert_equal zlib_read('test/precache/jst_test.js.gz'),
      File.read('test/fixtures/jammed/jst_test_from_cli.js')

    assert_equal zlib_read('test/precache/js_test_with_templates.js.gz'),
      File.read('test/fixtures/jammed/js_test_with_templates.js')
  end

  def test_lazy_precaching
    system("#{ JAMMIT } -c test/config/assets.yml -o test/precache -u http://www.example.com")
    assert_equal PRECACHED_FILES, glob('test/precache/*')
    mtime = File.mtime(PRECACHED_FILES.first)
    system("#{ JAMMIT } -c test/config/assets.yml -o test/precache -u http://www.example.com")
    assert_equal File.mtime(PRECACHED_FILES.first), mtime
    system("#{ JAMMIT } -c test/config/assets.yml -o test/precache -u http://www.example.com --force")
    new_mtime = File.mtime(PRECACHED_FILES.first)
    assert new_mtime > mtime,
      "#{ PRECACHED_FILES.first } mtime - #{ new_mtime } - greater than #{ mtime }"
  end

  def test_generate_source_maps
    system("#{ JAMMIT } -c test/config/assets-sourcemaps.yml -o test/precache -u http://www.example.com")
    assert File.exist?("test/precache/maps/js_test.js.map"), "source map exists"

    js_map = JSON.parse(File.read("test/precache/maps/js_test.js.map"))

    assert_equal js_map["file"], "test/precache/js_test.js"
    assert_equal js_map["sources"], ["test/fixtures/src/test1.js", "test/fixtures/src/test2.js"]
  end

  def zlib_read(filename)
    Zlib::GzipReader.open(filename) {|f| f.read }
  end

end
