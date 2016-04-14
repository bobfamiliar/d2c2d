using System.Web.Http;

namespace ProvisionAPI
{
    public static class WebApiConfig
    {
        public static void Register(HttpConfiguration config)
        {
            // DISABLED CHECK FOR SHARED SECRET FOR VERSION OF LAB
            // THAT DOESN"T USE API MANAGEMENT
            // Web API configuration and services
            //config.MessageHandlers.Add(new ApiKeyHandler());

            // Web API routes
            config.MapHttpAttributeRoutes();

            config.Routes.MapHttpRoute(
                name: "DefaultApi",
                routeTemplate: "api/{controller}/{id}",
                defaults: new { id = RouteParameter.Optional }
            );
        }
    }
}
