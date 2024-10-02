#ifdef WIN32
#define strcasecmp _stricmp
#define strncasecmp _strnicmp

static char *strcasestr(const char *haystack, const char *needle)
{
int i;
int matchamt=0;

  for(i=0;i<haystack[i];i++)
  {
    if (tolower(haystack[i]) != tolower(needle[matchamt]))
    {
      matchamt = 0;
    }
    if (tolower(haystack[i]) == tolower(needle[matchamt]))
    {
      matchamt++;
      if (needle[matchamt]==0) return (char *)1;
    }
  }
  return 0;
}
#endif
