defmodule Explorer.Chain.Address.BVConverter do
  @moduledoc """
  BV address format converter (Base58Check variant).

  Encoding: 20-byte binary -> BV string
  Decoding: BV string -> 0x hex (with SHA256 Checksum verification)
  """

  @bv_prefix "BV"
  @address_bytes 20
  @checksum_bytes 4

  @doc "Encodes a 20-byte binary address to a BV string"
  @spec encode(binary()) :: String.t()
  def encode(<<bytes::binary-size(@address_bytes)>>) do
    checksum = :crypto.hash(:sha256, bytes) |> binary_part(0, @checksum_bytes)
    encoded = Base58.encode58(bytes <> checksum)
    @bv_prefix <> encoded
  end

  def encode(other), do: other

  @doc "Decodes a BV string to a 0x hex address (with Checksum verification)"
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
