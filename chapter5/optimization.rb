require 'time'

$people = [ %w-Seymour BOS-,
            %w-Franny DAL-,
            %w-Zooey CAK-,
            %w-Walt MIA-,
            %w-Buddy ORD-,
            %w-Les OMA- ]

$destination = 'LGA'

$flights = {}

File.read('schedule.txt').split("\n").each do |line|
  origin, dest, depart, arrive, price = line.strip.split(',')
  $flights[[origin,dest]] ||= []
  $flights[[origin,dest]] << [depart, arrive, price.to_i]
end

def get_minutes(t)
  x = Time.parse(t)
  x.min + 60*x.hour
end

def print_schedule(r)
  (r.size/2).times do |d|
    name, origin = *$people[d][0..1]
    out = $flights[[origin,$destination]][r[d]]
    ret = $flights[[$destination,origin]][r[d+1]]
    puts "%10s%10s %5s-%5s $%3s %5s-%5s $%3s" % ([name, origin] + out + ret)
  end
end

def schedule_cost(sol)
  total_price = 0
  latest_arrival = 0
  earliest_dep = 24*60
  
  (sol.size/2).times do |d|
    # Get the inbound and outbound flights
    origin = $people[d][1]
    outbound = $flights[[origin,$destination]][sol[d].to_i]
    returnf = $flights[[$destination,origin]][sol[d+1].to_i]
    
    # Total price is price of all outbound and return flights
    total_price += outbound[2].to_i + returnf[2].to_i
    
    # Track the latest arrival and earliest departure
    latest_arrival = get_minutes(outbound[1]) if latest_arrival < get_minutes(outbound[1])
    earliest_dep = get_minutes(returnf[0]) if earliest_dep > get_minutes(returnf[0])
  end
    
  # Every person must wait at the airport until the latest person arrives.
  # They also must arrive at the same time and wait for their flights.
  total_wait = 0
  (sol.size/2).times do |d|
    # Get the inbound and outbound flights
    origin = $people[d][1]
    outbound = $flights[[origin,$destination]][sol[d].to_i]
    returnf = $flights[[$destination,origin]][sol[d+1].to_i]
    
    total_wait += (latest_arrival - get_minutes(outbound[1])) +
                  (get_minutes(returnf[0]) - earliest_dep)
  end
  
  # Does this solution require an extra day of car rental? That'll be $50!
  total_price += 50 if latest_arrival > earliest_dep
  
  total_price + total_wait
end

def random_optimize(domain, costf)
  best = 999999999
  bestr = nil
  1000.times do |i|
    # Create a random solution
    r = domain.map { |d| d.first + rand(d.last - d.first) }
    
    # Get the cost
    cost = costf[r]
    
    # Compare it to the best one so far
    if cost < best
      best = cost
      bestr = r
    end
  end
  bestr
end

def hill_climb(domain, costf)
  # Create a random solution
  sol = domain.map { |d| d.first + rand(d.last - d.first) }
  
  # Main loop
  loop do
    
    # Create a list of neighbouring solutions
    neighbours = []
    domain.size.times do |j|
      
      # One away in each direction
      neighbours.push(sol[0...j] + [sol[j]+1] + sol[(j+1)..-1]) if sol[j] > domain[j].first
      neighbours.push(sol[0...j] + [sol[j]-1] + sol[(j+1)..-1]) if sol[j] < domain[j].last
    end
    
    # See what the best solution among the neighbours is
    current = costf[sol]
    best = current
    neighbours.each do |neighbour|
      cost = costf[neighbour]
      if cost < best
        best = cost
        sol = neighbour
      end
    end
    
    # If there's no improvement, we've reached the top
    break if best == current
  end
  sol
end

domain = [0..8] * $people.size * 2
s = hill_climb(domain, method(:schedule_cost))
puts schedule_cost(s)
print_schedule(s)

