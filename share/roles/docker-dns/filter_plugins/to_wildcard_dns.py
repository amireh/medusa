def to_wildcard_dns(hostnames, target):
  return ['{}={}'.format(x, target) for x in hostnames]

class FilterModule(object):
  def filters(self):
    return {'to_wildcard_dns': to_wildcard_dns}
