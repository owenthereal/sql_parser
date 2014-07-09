dir = File.dirname(__FILE__)
require File.expand_path("#{dir}/spec_helper")

shared_context "SqlParser" do
  before do
    @parser = SqlParser.new
  end

  def parse(input)
    @parser.parse(input).tap do |result|
      puts result.failure_reason unless result
    end
  end
end

describe SqlParser, "parsing" do
  include_context "SqlParser"
  
  it "when conditions are not joined with an :and or :or, does not succeed" do
    expect(@parser.parse("select first_name from users where first_name='joe' last_name='bob'")).to be_nil
  end
end

describe SqlParser, "#tree when parsing select statement" do
  include_context "SqlParser"

  it "parses a multi field, table, and where clause statement" do
    expect(parse("select distinct *, first_name, last_name, middle_name from users, accounts, logins where first_name='joe' and last_name='bob' or age > 25").tree).to eq({
      :operator => :select,
      :set_quantifier => :distinct,
      :fields => [:'*', :first_name, :last_name, :middle_name],
      :tables => [:users, :accounts, :logins],
      :conditions => [
        {:operator => :'=', :field => :first_name, :value => 'joe'},
        {:operator => :and},
        {:operator => :'=', :field => :last_name, :value => 'bob'},
        {:operator => :or},
        {:operator => :'>', :field => :age, :value => 25}
      ]
    })
  end
end

describe SqlParser, "#operator when parsing select statement" do
  include_context "SqlParser"

  it "returns :select" do
    expect(parse("select first_name").operator).to eq(:select)
  end
end

describe SqlParser, "#set_quantifier when parsing select statement" do
  include_context "SqlParser"

  it "when parsing distinct, returns :distinct" do
    expect(parse("select distinct first_name").set_quantifier).to eq(:distinct)
  end

  it "when parsing all, returns :all" do
    expect(parse("select all first_name").set_quantifier).to eq(:all)
  end
end

describe SqlParser, "#fields when parsing select statement" do
  include_context "SqlParser"

  it "returns the fields in the statement" do
    expect(parse("select first_name").fields).to eq([:first_name])
    expect(parse("select first_name, last_name, middle_name").fields).to eq([
      :first_name, :last_name, :middle_name
    ])
  end

  it "when receiving *, returns * in the fields list" do
    expect(parse("select *").fields).to eq([:'*'])
  end
end

describe SqlParser, "#tables when parsing select statement" do
  include_context "SqlParser"

  it "returns tables from the statement" do
    expect(parse("select first_name from users").tables).to eq([:users])
    expect(parse("select first_name from users, accounts, logins").tables).to eq([
      :users, :accounts, :logins
    ])
  end
end

describe SqlParser, "#conditions when parsing select statement" do
  include_context "SqlParser"
  
  it "when no where conditions, returns empty array" do
    expect(parse("select first_name from users").conditions).to eq([])
  end

  it "returns equality conditions from the statement" do
    expect(parse("select first_name from users where id=3").conditions).to eq([
      { :operator => :'=', :field => :id, :value => 3 }
    ])
    expect(parse("select first_name from users where first_name='joe'").conditions).to eq([
      { :operator => :'=', :field => :first_name, :value => 'joe' }
    ])
    
    expect(parse("select first_name from users where first_name='joe' and last_name='bob'").conditions).to eq([
      {:operator => :'=', :field => :first_name, :value => 'joe'},
      {:operator => :and},
      {:operator => :'=', :field => :last_name, :value => 'bob'}
    ])
  end

  it "returns greater than conditions from the statement" do
    expect(parse("select first_name from users where id>3").conditions).to eq [
      { :operator => :'>', :field => :id, :value => 3 }
    ]

    expect(parse("select first_name from users where id>3 and age>25").conditions).to eq [
      {:operator => :'>', :field => :id, :value => 3},
      {:operator => :and},
      {:operator => :'>', :field => :age, :value => 25}
    ]
  end

  it "returns less than conditions from the statement" do
    expect(parse("select first_name from users where id<3").conditions).to eq([
      { :operator => :'<', :field => :id, :value => 3 }
    ])

    expect(parse("select first_name from users where id<3 and age<25").conditions).to eq([
      {:operator => :'<', :field => :id, :value => 3},
      {:operator => :and},
      {:operator => :'<', :field => :age, :value => 25}
    ])
  end

  it "returns greater than or equal to conditions from the statement" do
    expect(parse("select first_name from users where id>=3").conditions).to eq([
      { :operator => :'>=', :field => :id, :value => 3 }
    ])

    expect(parse("select first_name from users where id>=3 and age>=25").conditions).to eq([
      {:operator => :'>=', :field => :id, :value => 3},
      {:operator => :and},
      {:operator => :'>=', :field => :age, :value => 25}
    ])
  end

  it "returns less than or equal to conditions from the statement" do
    expect(parse("select first_name from users where id<=3").conditions).to eq([
      { :operator => :'<=', :field => :id, :value => 3 }
    ])

    expect(parse("select first_name from users where id<=3 and age<=25").conditions).to eq([
      {:operator => :'<=', :field => :id, :value => 3},
      {:operator => :and},
      {:operator => :'<=', :field => :age, :value => 25}
    ])
  end

  it "returns not equal to conditions from the statement" do
    expect(parse("select first_name from users where id<>3").conditions).to eq([
      { :operator => :'<>', :field => :id, :value => 3 }
    ])

    expect(parse("select first_name from users where id<>3 and age<>25").conditions).to eq([
      {:operator => :'<>', :field => :id, :value => 3},
      {:operator => :and},
      {:operator => :'<>', :field => :age, :value => 25}
    ])
  end
end

describe SqlParser, "#conditions when parsing select statement with :and operators" do
  include_context "SqlParser"

  it "returns single level :and operation" do
    expect(parse("select first_name from users where first_name='joe' and last_name='bob'").conditions).to eq([
      {:operator => :'=', :field => :first_name, :value => 'joe'},
      {:operator => :and},
      {:operator => :'=', :field => :last_name, :value => 'bob'}
    ])
  end

  it "returns nested :and operations from the statement" do
    expect(parse("select first_name from users where first_name='joe' and last_name='bob' and middle_name='pat'").conditions).to eq([
      {:operator => :'=', :field => :first_name, :value => 'joe'},
      {:operator => :and},
      {:operator => :'=', :field => :last_name, :value => 'bob'},
      {:operator => :and},
      {:operator => :'=', :field => :middle_name, :value => 'pat'}
    ])
  end
end

describe SqlParser, "#conditions when parsing select statement with :or operators" do
  include_context "SqlParser"

  it "returns single level :and operation" do
    expect(parse("select first_name from users where first_name='joe' or last_name='bob'").conditions).to eq([
      {:operator => :'=', :field => :first_name, :value => 'joe'},
      {:operator => :or},
      {:operator => :'=', :field => :last_name, :value => 'bob'}
    ])
  end

  it "returns nested :or operations from the statement" do
    expect(parse("select first_name from users where first_name='joe' or last_name='bob' or middle_name='pat'").conditions).to eq([
      {:operator => :'=', :field => :first_name, :value => 'joe'},
      {:operator => :or},
      {:operator => :'=', :field => :last_name, :value => 'bob'},
      {:operator => :or},
      {:operator => :'=', :field => :middle_name, :value => 'pat'}
    ])
  end
end

describe SqlParser, "#conditions when parsing select statement with :and and :or operators" do
  include_context "SqlParser"

  it "returns :and having precedence over :or" do
    expect(parse("select first_name from users where age > 25 and first_name='joe' or last_name='bob'").conditions).to eq([
      {:operator => :'>', :field => :age, :value => 25},
      {:operator => :and},
      {:operator => :'=', :field => :first_name, :value => 'joe'},
      {:operator => :or},
      {:operator => :'=', :field => :last_name, :value => 'bob'}
    ])
  end
end
