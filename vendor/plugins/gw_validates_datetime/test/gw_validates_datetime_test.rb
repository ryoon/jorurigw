require File.dirname(__FILE__) + '/test_helper'
require 'pp'

class GwValidatesDatetimeTest < ActiveSupport::TestCase
  fixtures :datetime_str, :valid_unlike_str

  def setup
    @valid_datetime_str = '2009/07/17 14:47:38'
    @invalid_datetime_str = 'invalid_example.'
  end

  def test_should_allow_valid_datetime_strs
    [
      '2009/07/17',
      '2009/7/17',
      '2009-07-17',
      '2009-7-17',
      ' 2009-7-17 ',
      '2009-7-17 0:0',
      '2009-7-17 0:00',
      '2009-7-17 00:00',
      '2009-7-17 23:59',
      '2009-7-17 23:59:00', # now error
      '0:0', # now error
      '0:00', # now error
      '00:00', # now error
      '23:59', # now error
      '23:59:00', # now error
      '9999-12-31',
      '9999-12-31 23:59:00', # now error
    ].each do |dd|
      p = create_datetime_str(:datetime_str => dd)
      save_passes(p, dd)
    end
  end

  def test_should_not_allow_invalid_datetime_strs
    [
      'invalid_example.',
      '200a/07/17',
      '2009/0a/17',
      '2009/07/a',
#      '2009-7-17 a:0', # => '2009-7-17'
#      '2009-7-17 0:a', # => '2009-7-17'
#      '2009-7-17 23:59:a', # => '2009-7-17'
      'a:0',
      '0:a',
#      '23:59:a',
      '2009/2/29',
      '2009/13/2',
#      '2009/-1/2', # => '1/2'
#      '2009/1/-2', # => '2009/1/2'
      '2009/1/55',
      '2009/7/40',
    ].each do |dd|
      p = create_datetime_str(:datetime_str => dd)
      save_fails(p, dd)
    end
  end
  def test_should_allow_valid_unlike
    [
      '012345',
      'あいうえお',
      '',
      "\n",
    ].each do |dd|
      p = ValidUnlikeStr.new(:str => dd)
      assert p.valid?, " validating #{dd}"
      assert p.save
      assert_nil p.errors.on(:str)
      hk = NoHankanaStrBySelf.new(:str => dd)
      assert hk.valid?, " validating #{dd}"
      assert hk.save
      assert_nil hk.errors.on(:str)
    end
  end
  def test_should_not_allow_valid_unlike
    [
      'a',
      'abc',
      '0123abc',
    ].each do |dd|
      p = ValidUnlikeStr.new(:str => dd)
      assert !p.valid?, " validating #{dd}"
      assert !p.save
      assert p.errors.on(:str)
    end
    [
      'ｱ',
      'ab｡c',
      '012ﾟ 3abc',
    ].each do |dd|
      p = NoHankanaStrBySelf.new(:str => dd)
      assert !p.valid?, " validating #{dd}"
      assert !p.save
      assert p.errors.on(:str)
    end
  end
  def test_should_allow_valid_unlike_hankana
    [
      '012345',
      'あいうえお',
      '',
      "\n",
    ].each do |dd|
      p = NoHankanaStr.new(:str => dd)
      assert p.valid?, " validating #{dd}"
      assert p.save
      assert_nil p.errors.on(:str)
      p = NoHankanaStrBySelf.new(:str => dd)
      assert p.valid?, " validating #{dd}"
      assert p.save
      assert_nil p.errors.on(:str)
    end
  end
  def test_should_notallow_valid_unlike_hankana
    [
      'ｱ',
      'ab｡c',
      '012ﾟ 3abc',
    ].each do |dd|
      p = NoHankanaStr.new(:str => dd)
      assert !p.valid?, " validating #{dd}"
      assert !p.save
      assert p.errors.on(:str)
      p = NoHankanaStrBySelf.new(:str => dd)
      assert !p.valid?, " validating #{dd}"
      assert !p.save
      assert p.errors.on(:str)
    end
  end
protected
  def create_datetime_str(params)
    DatetimeStr.new(params)
  end
  def save_passes(p, dd = '')
    assert p.valid?, " validating #{dd}"
    assert p.save
    assert_nil p.errors.on(:datetime_str)
  end

  def save_fails(p, dd = '')
    assert !p.valid?, " validating #{dd}"
    assert !p.save
    assert p.errors.on(:datetime_str)
  end
end

module Kernel
  private
  def pp(*objs)
    logger = Logger.new File.join(File.dirname(__FILE__), '..', 'log', 'out.log')
    objs.each { |obj| logger.debug PP.pp(obj, '') }
    nil
  end
end
