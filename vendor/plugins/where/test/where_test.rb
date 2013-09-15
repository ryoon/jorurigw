require File.dirname(__FILE__) + '/test_helper'

class WhereTest < Test::Unit::TestCase
    
    fixtures :items
    
  def test_sql
    
        assert Order.get_sql( :all, :conditions => ["name = ?", "abc"] )
        assert_equal "SELECT * FROM orders WHERE (name = 'abc') ", 
                      Order.get_sql( :all, :conditions => ["name = ?", "abc"])
        assert_equal "SELECT * FROM orders WHERE (name = 'abc') ", 
                      Order.get_sql( :all, :conditions => ["name = ?", "abc"], :include => :item )
    
  end



  def test_cond1a
     c = InVisible::Cond.new do
        month '<=', 11
        year '=', 2005
        name 'LIKE', 'ruby%'
      end

      assert_equal ["month <= ? and year = ? and name LIKE ?", 11, 2005, "ruby%"], c.where
  end

  def test_cond1b
     c = InVisible::Cond.new do
        month '<=', 11
        year 2005
        name 'LIKE', 'ruby%'
      end
      assert_equal ["month <= ? and year = ? and name LIKE ?", 11, 2005, "ruby%"], c.where
  end

  def test_cond2
     c = InVisible::Cond.new do
        date 'between', '2005-06-01', '2005-06-30'
      end
      assert_equal ["date between ? and ?", '2005-06-01', '2005-06-30'], c.where
  end

  def test_cond3
     c = InVisible::Cond.new do
        date 'between', '2005-06-01', '2005-06-30'
        name '=', 'FooBar'
      end
      assert_equal ["date between ? and ? and name = ?", '2005-06-01', '2005-06-30', 'FooBar'], c.where
  end

  def test_cond4
      c = InVisible::Cond.new do
         name '=', 'host1'
         sql "hosts.id = logs.host_id and hosts.name", 'like', "123.23.45.67"
      end
      assert_equal ["name = ? and hosts.id = logs.host_id and hosts.name like ?", 'host1', '123.23.45.67'], c.where
  end
  
  def test_cond5
     c = InVisible::Cond.new do
         name '=', "bla"
         sql "eventtime > now() - interval '1 day'"
     end
     assert_equal ["name = ? and eventtime > now() - interval '1 day'", 'bla'], c.where
  end
  
  def test_add
      c = InVisible::Cond.new do
          name '=', "bla"
      end
      c << ['date', 'between', '2006-01-01', '2006-01-30']
      assert_equal ["name = ? and date between ? and ?", 'bla', '2006-01-01', '2006-01-30'], c.where
  end
  
  
  def test_inet
      c = InVisible::Cond.new do
          ip '= inet', "12.34.56.78/24"
      end
  
      assert_equal ["ip = inet ?", "12.34.56.78/24"], c.where
  end
  
  def test_empty_block
    c = InVisible::Cond.new
    assert_equal [""], c.where
  end
  
  def test_block1
     orders = Item.find_with_conditions( :all, :limit => 10 ) do
                  name '=', 'Item1'
              end 
     assert_equal 1, orders.size
  end
  
  def test_block2
     orders = Item.find_with_conditions( :all, :limit => 10 ) do 
                  name 'like', 'Item%'
              end 
     assert_equal 2, orders.size
  end
  
  def test_block3
     order = Item.find_with_conditions( :first ) do
                  name 'like', 'Item%'
              end 
     assert_equal Item, order.class
  end
    
  def test_empty_block
    orders = Item.find_with_conditions( :all ) 
    assert_equal 2, orders.size
    
  end


end