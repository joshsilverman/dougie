namespace :export do

  task :reps => :environment do
    reps = Rep.where("reps.id > 990").order(:mem_id)
    File.open("tmp/reps.csv", "w") do |f|
      reps.each do |rep|
        f.puts "#{rep.id} #{rep.created_at.to_i} #{rep.mem_id} #{rep.user_id} #{rep.confidence} #{rep.strength}\n"
      end
    end
  end

  task :mems => :environment do
    mems = Mem.where(:status => "1").order(:id)
    File.open("tmp/mems.csv", "w") do |f|
      mems.each do |mem| mem
        f.puts "#{mem.created_at.to_i} #{mem.review_after.to_i} #{mem.strength} #{mem.updated_at.to_i}\n"
      end
    end
  end

  task :memory => [:mems, :reps]
end