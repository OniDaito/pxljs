'''
Run a basic webserver with some Python3

oni@section9.co.uk

'''


import sys, os
from http.server import HTTPServer, BaseHTTPRequestHandler, SimpleHTTPRequestHandler

class MyRequestHandler( SimpleHTTPRequestHandler ):
  def do_GET(self,*args,**kwds):
    tmp = self.path.split('/')
    # redirect?
    if (len(tmp) == 3) and (tmp[0] == tmp[2]) and tmp[0] == '':
      self.send_response(301)
      self.send_header('Location', self.path + 'html/')
    else:
      SimpleHTTPRequestHandler.do_GET(self,*args,**kwds)

if __name__ == "__main__":
	
  server_class = HTTPServer
  handler_class = MyRequestHandler
  server_address = ('', 8000)
  httpd = server_class(server_address, handler_class)
   	
  os.chdir(sys.argv[1])
  httpd.serve_forever()
  
