defmodule Explorer.Chain.Address.BVConverter do
  @moduledoc """
  BV 地址格式转换器（Base58Check 变体）。

  编码: 20字节二进制 → BV 字符串
  解码: BV 字符串 → 0x 十六进制（含 SHA256 Checksum 校验）
  """

  @bv_prefix "BV"
  @address_bytes 20
  @checksum_bytes 4

  @doc "将 20 字节二进制地址编码为 BV 字符串"
  @spec encode(binary()) :: String.t()
  def encode(<<bytes::binary-size(@address_bytes)>>) do
    checksum = :crypto.hash(:sha256, bytes) |> binary_part(0, @checksum_bytes)
    encoded = Base58.encode58(bytes <> checksum)
    @bv_prefix <> encoded
  end

  def encode(other), do: other

  @doc "将 BV 字符串解码为 0x 十六进制地址（含 Checksum 校验）"
  @spec decode_to_hex(String.t()) :: {:ok, String.t()} | {:error, atom()}
  def decode_to_hex(@bv_prefix <> base58_part) do
    with decoded when byte_size(decoded) == @address_bytes + @checksum_bytes <-
           Base58.decode58(base58_part),
         <<address_bytes::binary-size(@address_bytes), checksum::binary-size(@checksum_bytes)>> <-
           decoded,
         expected <- :crypto.hash(:sha256, address_bytes) |> binary_part(0, @checksum_bytes),
         true <- checksum == expected do
      {:ok, "0x" <> Base.encode16(address_bytes, case: :lower)}
    else
      {:error, _} -> {:error, :invalid_base58}
      _ -> {:error, :invalid_checksum}
    end
  end

  def decode_to_hex(other), do: {:ok, other}
end
