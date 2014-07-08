require "spec_helper"

describe Scheman::Parsers::Mysql do
  let(:instance) do
    described_class.new
  end

  describe ".parse" do
    subject do
      begin
        described_class.parse(str).to_hash
      rescue => exception
        puts exception.cause.ascii_tree rescue nil
        raise
      end
    end

    context "with full syntax" do
      let(:str) do
        <<-EOS.strip_heredoc
          # comment

          USE database_name;

          SET variable_name=value;

          DROP TABLE table_name;

          CREATE DATABASE database_name;

          CREATE TABLE `table1` (
            `column1` INTEGER(11) NOT NULL AUTO INCREMENT,
            `column2` VARCHAR(255) NOT NULL,
            PRIMARY KEY (`column1`)
          );

          ALTER TABLE table_name ADD FOREIGN KEY (column_name) REFERENCES table_name (column_name);

          INSERT INTO table_name (column_name) VALUES ('value');

          DELIMITER //
        EOS
      end

      it "succeeds in parse" do
        should == [
          {
            database_name: "database_name",
          },
          {
            create_table: {
              name: "table1",
              fields: [
                {
                  field: {
                    name: "column1",
                    type: "integer",
                    values: ["11"],
                    qualifiers: [
                      {
                        qualifier: {
                          type: "not_null",
                        },
                      },
                      {
                        qualifier: {
                          type: "auto_increment",
                        },
                      },
                    ],
                  },
                },
                {
                  field: {
                    name: "column2",
                    type: "varchar",
                    values: ["255"],
                    qualifiers: [
                      {
                        qualifier: {
                          type: "not_null",
                        },
                      },
                    ],
                  },
                },
              ],
              indices: [
                {
                  index: {
                    column: "column1",
                    primary: true,
                    name: nil,
                    type: nil,
                  },
                },
              ],
            },
          },
        ]
      end
    end

    context "with CREATE DATABASE" do
      let(:str) do
        "CREATE DATABASE database_name;"
      end

      it "succeeds in parse" do
        should == []
      end
    end

    context "with CREATE SCHEMA" do
      let(:str) do
        "CREATE SCHEMA database_name;"
      end

      it "succeeds in parse" do
        should == []
      end
    end

    context "with NOT NULL field qualifier" do
      let(:str) do
        "CREATE TABLE `table1` (`column1` INTEGER NOT NULL);"
      end

      it "succeeds in parse field qualifier" do
        subject[0][:create_table][:fields][0][:field][:qualifiers][0][:qualifier][:type].should == "not_null"
      end
    end

    context "with NULL field qualifier" do
      let(:str) do
        "CREATE TABLE `table1` (`column1` INTEGER NULL);"
      end

      it "succeeds in parse" do
        subject[0][:create_table][:fields][0][:field][:qualifiers][0][:qualifier][:type].should == "null"
      end
    end

    context "with AUTO INCREMENT field qualifier" do
      let(:str) do
        "CREATE TABLE `table1` (`column1` INTEGER AUTO INCREMENT);"
      end

      it "succeeds in parse" do
        subject[0][:create_table][:fields][0][:field][:qualifiers][0][:qualifier][:type].should == "auto_increment"
      end
    end

    context "with PRIMARY KEY field qualifier" do
      let(:str) do
        "CREATE TABLE `table1` (`column1` INTEGER PRIMARY KEY);"
      end

      it "succeeds in parse" do
        subject[0][:create_table][:fields][0][:field][:qualifiers][0][:qualifier][:type].should == "primary_key"
      end
    end

    context "with KEY field qualifier" do
      let(:str) do
        "CREATE TABLE `table1` (`column1` INTEGER KEY);"
      end

      it "succeeds in parse" do
        subject[0][:create_table][:fields][0][:field][:qualifiers][0][:qualifier][:type].should == "primary_key"
      end
    end

    context "with INDEX field qualifier" do
      let(:str) do
        "CREATE TABLE `table1` (`column1` INTEGER INDEX);"
      end

      it "succeeds in parse" do
        subject[0][:create_table][:fields][0][:field][:qualifiers][0][:qualifier][:type].should == "primary_key"
      end
    end

    context "with UNSIGNED field type qualifier" do
      let(:str) do
        "CREATE TABLE `table1` (`column1` INTEGER UNSIGNED);"
      end

      it "succeeds in parse" do
        subject[0][:create_table][:fields][0][:field][:qualifiers].should be_empty
      end
    end

    context "with CHARACTER SET field type qualifier" do
      let(:str) do
        "CREATE TABLE `table1` (`column1` VARCHAR(255) CHARACTER SET utf8);"
      end

      it "succeeds in parse" do
        subject[0][:create_table][:fields][0][:field][:qualifiers][0].should == {
          qualifier: {
            type: "character_set",
            value: "utf8",
          },
        }
      end
    end

    context "with COLLATE field type qualifier" do
      let(:str) do
        "CREATE TABLE `table1` (`column1` VARCHAR(255) COLLATE utf8_general_ci);"
      end

      it "succeeds in parse" do
        subject[0][:create_table][:fields][0][:field][:qualifiers][0].should == {
          qualifier: {
            type: "collate",
            value: "utf8_general_ci",
          },
        }
      end
    end

    context "with UNIQUE KEY field qualifier" do
      let(:str) do
        "CREATE TABLE `table1` (`column1` INTEGER UNIQUE KEY);"
      end

      it "succeeds in parse" do
        subject[0][:create_table][:fields][0][:field][:qualifiers][0][:qualifier][:type].should == "unique_key"
      end
    end

    context "with UNIQUE INDEX field qualifier" do
      let(:str) do
        "CREATE TABLE `table1` (`column1` INTEGER UNIQUE INDEX);"
      end

      it "succeeds in parse" do
        subject[0][:create_table][:fields][0][:field][:qualifiers][0][:qualifier][:type].should == "unique_key"
      end
    end

    context "with PRIMARY KEY" do
      let(:str) do
        <<-EOS.strip_heredoc
          CREATE TABLE `table1` (
            `column1` INTEGER,
            PRIMARY KEY (`column1`)
          );
        EOS
      end

      it "succeeds in parse" do
        subject[0][:create_table][:indices][0].should == {
          index: {
            column: "column1",
            name: nil,
            primary: true,
            type: nil,
          },
        }
      end
    end

    context "with PRIMARY KEY BTREE" do
      let(:str) do
        <<-EOS.strip_heredoc
          CREATE TABLE `table1` (
            `column1` INTEGER,
            PRIMARY KEY BTREE (`column1`)
          );
        EOS
      end

      it "succeeds in parse" do
        subject[0][:create_table][:indices][0].should == {
          index: {
            column: "column1",
            name: nil,
            primary: true,
            type: "btree",
          },
        }
      end
    end

    context "with PRIMARY KEY ... BTREE" do
      let(:str) do
        <<-EOS.strip_heredoc
          CREATE TABLE `table1` (
            `column1` INTEGER,
            PRIMARY KEY (`column1`) BTREE
          );
        EOS
      end

      it "succeeds in parse" do
        subject[0][:create_table][:indices][0].should == {
          index: {
            column: "column1",
            name: nil,
            primary: true,
            type: "btree",
          },
        }
      end
    end

    context "with KEY" do
      let(:str) do
        "CREATE TABLE `table1` (`column1` INTEGER, KEY index1 (`column1`));"
      end

      it "succeeds in parse" do
        subject[0][:create_table][:indices][0].should == {
          index: {
            column: "column1",
            name: "index1",
            type: nil,
          },
        }
      end
    end

    context "with USING BTREE" do
      let(:str) do
        "CREATE TABLE `table1` (`column1` INTEGER, KEY index1 USING BTREE (`column1`));"
      end

      it "succeeds in parse" do
        subject[0][:create_table][:indices][0].should == {
          index: {
            column: "column1",
            name: "index1",
            type: "btree",
          },
        }
      end
    end

    context "with USING BTREE after column name" do
      let(:str) do
        "CREATE TABLE `table1` (`column1` INTEGER, KEY index1 (`column1`) USING BTREE);"
      end

      it "succeeds in parse" do
        subject[0][:create_table][:indices][0].should == {
          index: {
            column: "column1",
            name: "index1",
            type: "btree",
          },
        }
      end
    end

    context "with FULLTEXT" do
      let(:str) do
        "CREATE TABLE `table1` (`column1` INTEGER, FULLTEXT index1 (`column1`));"
      end

      it "succeeds in parse" do
        subject[0][:create_table][:indices][0].should == {
          index: {
            column: "column1",
            name: "index1",
            type: "fulltext",
          },
        }
      end
    end

    context "with SPATIAL" do
      let(:str) do
        "CREATE TABLE `table1` (`column1` INTEGER, SPATIAL index1 (`column1`));"
      end

      it "succeeds in parse" do
        subject[0][:create_table][:indices][0].should == {
          index: {
            column: "column1",
            name: "index1",
            type: "spatial",
          },
        }
      end
    end
  end
end
