defmodule Grizzly.Node.Association.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Node.Association

  test "transform a Node Association into a keyword list" do
    association = Association.new(0x01, [0x01])
    keyword = Association.to_keyword(association)

    assert 0x01 == Keyword.get(keyword, :group)
    assert [0x01] == Keyword.get(keyword, :nodes)
  end
end
