"""
URL configuration for recruitment portal.
"""
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from django.http import JsonResponse

def root_view(request):
    """Root endpoint that provides API information"""
    return JsonResponse({
        "message": "Recruitment Portal API",
        "status": "active",
        "endpoints": {
            "admin": "/admin/",
            "api": "/api/",
            "health": "/api/health/",
            "candidates": "/api/candidates/",
            "jobs": "/api/jobs/",
            "resumes": "/api/resumes/",
            "search": "/api/search/"
        }
    })

urlpatterns = [
    path('', root_view, name='root'),
    path('admin/', admin.site.urls),
    path('api/', include('api.urls')),
]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT) 