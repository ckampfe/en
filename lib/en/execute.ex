defmodule En.Execute do
  @callback initialize(any) :: any
  @callback call(String.t, any) :: String.t
end