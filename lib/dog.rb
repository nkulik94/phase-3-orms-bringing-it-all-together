class Dog
    attr_accessor :id, :name, :breed

    def initialize(attributes, id: nil)
       attributes.each do |key, value|
        self.class.attr_accessor(key)
        self.send("#{key}=", value)
       end
    end


    def self.create_table
        sql = <<-SQL
        CREATE TABLE IF NOT EXISTS dogs (
            id INTEGER PRIMARY KEY,
            name TEXT,
            breed TEXT
        )
        SQL
        
        DB[:conn].execute(sql)
    end

    def self.drop_table
        DB[:conn].execute("DROP TABLE dogs")
    end

    def save
        if self.id
            update
        else
            sql = <<-SQL
            INSERT INTO dogs (name, breed)
            VALUES (?, ?)
            SQL

            DB[:conn].execute(sql, self.name, self.breed)

            self.id = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs")[0][0]

            self
        end
    end

    def self.create attributes
        dog = self.new(attributes)
        dog.save
    end

    def self.new_from_db row
        self.new(id: row[0], name: row[1], breed: row[2])
    end

    def self.all
        sql = <<-SQL
        SELECT * FROM dogs
        SQL

        DB[:conn].execute(sql).map { |row| new_from_db(row) }
    end

    def self.find_by_attribute(attribute, name_of_attribute)
        sql = <<-SQL
        SELECT *
        FROM dogs
        WHERE dogs.#{attribute} = ?
        SQL

        DB[:conn].execute(sql, name_of_attribute)
    end

    def self.find_by_name(name)
        right_dog = find_by_attribute("name", name).first

        self.new_from_db(right_dog)
    end

    def self.find(id)
        right_dog = find_by_attribute("id", id).first

        new_from_db(right_dog)
    end

    def self.find_or_create_by(attributes)
        # right_name = find_by_attribute("name", attribute[:name])
        # right_breed = find_by_attribute("breed", attributes[:breed])

        # right_dog = right_name & right_breed

        sql = <<-SQL
        SELECT *
        FROM dogs
        WHERE dogs.name = ?
        AND dogs.breed = ?
        SQL

       right_dog = DB[:conn].execute(sql, attributes[:name], attributes[:breed])

       right_dog.length > 0 ? new_from_db(right_dog.first) : create(attributes)
    end

    def update
        sql = <<-SQL
        UPDATE dogs
        SET name = ?
        WHERE id = ?
        SQL

        DB[:conn].execute(sql, self.name, self.id)
    end
end
