require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class WorksheetSyncFinalityTest < ActiveSupport::TestCase
  # allocate = inštancia bez initialize; testované metódy nepoužívajú ivary
  def imp
    WorksheetSync::Importer.allocate
  end

  def test_next_working_day_skips_weekend
    assert_equal Date.new(2026, 6, 25), imp.send(:next_working_day, Date.new(2026, 6, 24)) # St -> Št
    assert_equal Date.new(2026, 6, 29), imp.send(:next_working_day, Date.new(2026, 6, 26)) # Pia -> Po
  end

  def test_locked_only_after_next_working_day_passed
    wed = Date.new(2026, 6, 24)
    assert_equal false, imp.send(:locked?, wed, Date.new(2026, 6, 25)) # vo štvrtok ešte nie
    assert_equal true,  imp.send(:locked?, wed, Date.new(2026, 6, 26)) # v piatok už áno
    fri = Date.new(2026, 6, 26)
    assert_equal false, imp.send(:locked?, fri, Date.new(2026, 6, 29)) # v pondelok ešte nie
    assert_equal true,  imp.send(:locked?, fri, Date.new(2026, 6, 30)) # v utorok už áno
  end
end
