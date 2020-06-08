class HospitalCarerMapping < ApplicationRecord
	belongs_to :hospital
	belongs_to :user	

	delegate :addr, to: :user, allow_nil: true, prefix: true
	delegate :pref_commute_distance, to: :user, allow_nil: true, prefix: true
	delegate :addr, to: :hospital, allow_nil: true, prefix: true

	before_save :compute_distance
	before_save :set_defaults

	scope :enabled, -> { where enabled: true }
	scope :preferred, -> { where preferred: true }
	

	def set_defaults
		self.enabled = false if self.enabled == nil
		self.preferred = false if self.preferred == nil
	end

	def compute_distance
		self.distance = self.user.distance_from(self.hospital) if self.user
	end

	MAX_COMMUTE_DIST = 50			
	def self.populate_carers(hospital)
		# Existing mapping of hospital and carers
		exisiting_temps = HospitalCarerMapping.where(hospital_id: hospital.id).collect(&:user_id) 
		# Get the users who are not already mapped
		temps = User.temps
		temps = temps.where("id NOT in (?)", exisiting_temps) if exisiting_temps.length > 0
		# And who are in a MAX_COMMUTE_DIST radius to the hospital
		temps = temps.near([hospital.lat, hospital.lng], MAX_COMMUTE_DIST)
		
		temps.each do |temp|
			commute_distance = temp.distance_from([hospital.lat, hospital.lng])
			# Check if the temp wants to commute this distance
			if( commute_distance < temp.pref_commute_distance)
				ccm = HospitalCarerMapping.create(hospital_id: hospital.id, user_id: temp.id, 
													distance: commute_distance, enabled: true, preferred: false) 
				Rails.logger.debug "Creating HospitalCarerMapping #{ccm.id} for User #{temp.id} and Hospital #{hospital.id}, distance #{commute_distance}, pref #{temp.pref_commute_distance}"
			else
				Rails.logger.debug "Skipping HospitalCarerMapping for User #{temp.id} and Hospital #{hospital.id}, distance #{commute_distance}, pref #{temp.pref_commute_distance}"
			end
		end
		
		return nil
	end

end
