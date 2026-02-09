require "json"
require "ruby_llm"

class McpTools::NormalizeResumeTool < RubyLLM::Tool
  description "Receives structured and normalized recruitment data extracted from a resume, following the CurriculumExtraction schema"

  def initialize(cv_analysis)
    @cv_analysis = cv_analysis
  end

  params do
    object :personal_data do
      object :full_name do
        string :value
      end

      object :location do
        string :city
        string :country
        boolean :remote
      end

      object :email do
        string :value
      end

      object :phone do
        string :value
      end

      object :links do
        string :github
        string :linkedin
        string :portfolio
        string :technical_blog
      end
    end

    object :professional_summary do
      object :current_role do
        string :value
      end

      object :estimated_years_experience do
        number :value
        string :method
        string :confidence
      end

      array :primary_stack, of: :string
      string :primary_area
    end

    object :technical_skills do
      array :languages do
        object do
          string :name
          number :estimated_experience_years
          string :level
        end
      end

      array :frameworks_and_libraries do
        object do
          string :name
          string :associated_stack
        end
      end

      object :databases do
        array :relational, of: :string
        array :non_relational, of: :string
      end

      object :cloud_and_infra do
        array :providers, of: :string
        array :tools, of: :string
      end

      object :general_tools do
        array :version_control, of: :string
        array :ci_cd, of: :string
        array :observability, of: :string
      end
    end

    array :professional_experience do
      object do
        string :company
        string :role

        object :period do
          string :start
          string :end
        end

        integer :total_time_in_role_months
        array :responsibilities, of: :string
        array :technologies_used, of: :string
      end
    end

    array :education do
      object do
        string :course
        string :institution
        string :degree
        string :status
        integer :conclusion_year
      end
    end

    array :certifications do
      object do
        string :name
        string :issuer
        integer :year
        string :area
      end
    end

    array :languages do
      object do
        string :language
        string :proficiency
      end
    end

    object :advanced_inferences do
      object :estimated_seniority do
        string :value
        string :confidence
        array :criteria, of: :string
      end

      object :environment_type do
        string :value
        string :confidence
      end

      object :experience_flags do
        boolean :distributed_systems
        boolean :high_scale
        boolean :performance_optimization
        boolean :security
      end
    end
  end

  def execute(args)
    @cv_analysis.update!(
      analysis_result: args.to_json,
      status: :completed
    )

    { status: "success" }
  rescue => e
    {
      status: "error",
      error: e.message
    }
  end
end
