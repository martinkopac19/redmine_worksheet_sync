require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class WorksheetSyncParserTest < ActiveSupport::TestCase
  RE = WorksheetSync::Importer::TITLE_RE

  def test_matches_tag_with_comment
    m = RE.match('#52291 Promotion update frequency')
    assert m
    assert_equal '52291', m[1]
    assert_equal 'Promotion update frequency', (m[2] || '').strip
  end

  def test_matches_bare_tag_without_comment
    m = RE.match('#55355')
    assert m
    assert_equal '55355', m[1]
    assert_equal '', (m[2] || '').strip
  end

  def test_matches_number_without_hash
    m = RE.match('55310')
    assert m
    assert_equal '55310', m[1]
    assert_equal '', (m[2] || '').strip
  end

  def test_matches_number_without_hash_with_comment
    m = RE.match('55310 fix pricing')
    assert m
    assert_equal '55310', m[1]
    assert_equal 'fix pricing', (m[2] || '').strip
  end

  def test_trims_and_keeps_inner_spaces
    m = RE.match('  #52291   viac   slov  ')
    assert m
    assert_equal '52291', m[1]
    assert_equal 'viac   slov', (m[2] || '').strip
  end

  def test_rejects_number_glued_to_text
    assert_nil RE.match('#52291foo')
  end

  def test_rejects_text_without_tag
    assert_nil RE.match('just some text')
  end
end
