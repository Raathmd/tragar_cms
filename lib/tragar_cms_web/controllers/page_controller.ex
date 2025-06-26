defmodule TragarCmsWeb.PageController do
  use TragarCmsWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
