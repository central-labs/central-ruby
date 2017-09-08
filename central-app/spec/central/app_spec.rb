require "spec_helper"

RSpec.describe Central::App do
  it "has a version number" do
    expect(Central::App::VERSION).not_to be nil
  end

  it "does something useful" do
    expect(false).to eq(true)
  end
end
