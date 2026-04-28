defmodule Explorer.Chain.Address.BVConverterTest do
  use ExUnit.Case, async: true
  alias Explorer.Chain.Address.BVConverter

  @test_address <<0x12, 0x34, 0x56, 0x78, 0x90, 0xAB, 0xCD, 0xEF,
                  0x12, 0x34, 0x56, 0x78, 0x90, 0xAB, 0xCD, 0xEF,
                  0x12, 0x34, 0x56, 0x78>>
  @test_hex "0x1234567890abcdef1234567890abcdef12345678"

  describe "encode/1" do
    test "将 20 字节二进制编码为 BV 格式字符串" do
      result = BVConverter.encode(@test_address)
      assert String.starts_with?(result, "BV")
      assert String.match?(result, ~r/^BV[1-9A-HJ-NP-Za-km-z]+$/)
    end

    test "非 20 字节输入原样返回" do
      assert BVConverter.encode(<<0::size(256)>>) == <<0::size(256)>>
      assert BVConverter.encode(<<>>) == <<>>
    end

    test "全零地址编码正确" do
      zero_address = <<0::size(160)>>
      result = BVConverter.encode(zero_address)
      assert String.starts_with?(result, "BV")
    end
  end

  describe "decode_to_hex/1" do
    test "BV 字符串正确解码为 0x 十六进制" do
      bv = BVConverter.encode(@test_address)
      assert {:ok, @test_hex} == BVConverter.decode_to_hex(bv)
    end

    test "编解码往返一致性" do
      bv = BVConverter.encode(@test_address)
      assert {:ok, restored} = BVConverter.decode_to_hex(bv)
      assert restored == @test_hex
    end

    test "篡改 BV 地址后校验失败" do
      bv = BVConverter.encode(@test_address)
      tampered = String.slice(bv, 0..-2) <> "X"
      assert {:error, :invalid_checksum} == BVConverter.decode_to_hex(tampered)
    end

    test "无效 Base58 输入返回错误" do
      assert {:error, _} = BVConverter.decode_to_hex("BV0OIl")
    end

    test "非 BV 前缀输入透传" do
      assert {:ok, @test_hex} == BVConverter.decode_to_hex(@test_hex)
    end

    test "空 BV 前缀返回错误" do
      assert {:error, _} = BVConverter.decode_to_hex("BV")
    end
  end
end
