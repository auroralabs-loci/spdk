NVMe reconnect skips Identify CNS 03h when the namespace NGUID and EUI64 are unchanged, instead
of issuing it once per namespace. The cached namespace UUID and CSI are reused, which shortens
reconnect on controllers with many namespaces. The same skip applies to namespace attribute notices.
