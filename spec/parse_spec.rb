require './spec_helper'

FILE = 'fixtures/event_upgrades_controller.rb'
RSpec.describe Parse do
  let(:p) { Parse.new FILE }
  it '#initialize' do
    expect(p.filename).to eq(FILE)
    expect(p.code.size).to be > 0
    expect(p.ast.class).to eq(Parser::AST::Node)
  end

  it '#find_before_actions' do
    expect(p.find_before_actions).to eq([:find_organiztion, :grant_permissions_for_organization, :check_business_info_type, :get_order])
  end

  it 'find_method' do
    expect(p.find_method(:find_organiztion).loc.keyword.line).to eq(44)
  end

  it 'find_relative_key_on_ast' do
    ast = p.find_method(:check_business_info_type)
    expect(p.find_relative_key_on_ast(ast)).to eq([{ :line => 50, :key => '.plase_fill_in_info_for_invoice_generation' }])
  end
end
