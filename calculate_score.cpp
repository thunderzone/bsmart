#include <iostream>
#include <fstream>
#include <string>
#include <sstream>
#include <vector>
using namespace std;

int main() {
  string line;

  ifstream myfile ("input.txt");
  int nv, ne, nr, nc, nx, total_caches = 0;
  if (myfile.is_open()) {
  	getline (myfile, line);
  	stringstream ss(line);
    ss >> nv >> ne >> nr >> nc >> nx;
    myfile.close();
  }
  else {
  	cout << "Unable to open output file for the first time\n"; 
  }
  //cout<<"Parsed input for the first time\n";
    //Parse output file
  //int cache_video[nc][nv] = {0};
  //int endpoint_cache[ne][nc] = {0};
  vector<vector<int> > cache_video (nc + 1 ,vector<int>(nv, 0));
  vector<vector<int> > endpoint_cache (ne, vector<int>(nc + 1, 0));
  vector<vector<int> > endpoint_video (ne, vector<int>(nv, 0));
  ifstream myoutfile ("output.txt");

	for (int j=0; j<nv; j++) {
		cache_video[nc][j] = 1;
	}
  int caches_used;
  if (myoutfile.is_open()) {
  	int line_no = 0;
    while ( getline (myoutfile, line) ) {
    	line_no++;
    	stringstream ss(line);
    	if (line_no == 1) {
    		ss >> caches_used;
    		//cout<<"caches_used: "<<caches_used<<endl;
    		for (int i=0; i<caches_used; i++) {
    			getline (myoutfile, line);
    			//Split numbers by space
    			istringstream iss(line);
				int temp;
				while(iss >> temp)
				{
					int cache_server = temp;
					iss >> temp;
					//cout<<"cache_server: "<<cache_server<<" video: "<<temp<<endl;
				    cache_video[cache_server][temp] = 1;
				    cache_video[nc][temp] = 1;
				}

    			line_no++;
    		}
    	}
    }
    myoutfile.close();
  }
  else {
  	cout << "Unable to open output file"; 
  }

  //cout<<"Parsed output\n";
  //Parse input file
  vector<vector<int> > requests;
  vector<int> endpoints;
  int line_no = 0, e_num = 0;
  bool fetching_endpoints = false;
  bool fetching_requests = false;
  myfile.open ("input.txt", std::ifstream::in);
  if (myfile.is_open())
  {
    while ( getline (myfile, line) )
    {
    	line_no++;
    	//cout<<"On line: "<<line_no<<endl;
    	stringstream ss(line);
    	if (line_no == 1) {
    		ss >> nv >> ne >> nr >> nc >> nx;
    	}
    	else if (line_no == 3) {
    		fetching_endpoints = true;
    	}

    	if (fetching_endpoints) {
    		//cout<<"fetching_endpoints"<<endl;
    		int min_lat, lat_dc, num_caches, cache_num, lat_cache;
    		ss >> lat_dc >> num_caches;
    		total_caches += num_caches;
    		endpoint_cache[e_num][nc] = lat_dc;
    		for (int i=0; i<num_caches; i++) {
    			getline (myfile, line);
    			stringstream ss1(line);
    			ss1 >> cache_num >> lat_cache;
    			endpoint_cache[e_num][cache_num] = lat_cache;
    			line_no++;
    		}
    		e_num++;
    		//endpoints.push_back(min_lat);
    	}
    	//cout<<"break point: "<<ne + total_caches<<endl;
    	if (fetching_endpoints && line_no == (ne + total_caches + 2)) {
    		//cout<<"Fetching request from now\n";
    		//cout<<"no. endpoints: "<<ne<<" total_caches: "<<total_caches<<endl;
    		fetching_endpoints = false;
    		fetching_requests = true;
    		continue;
    	}

    	if (fetching_requests) {
    		//cout<<"fetching requests"<<endl;
    		int video_num, endpoint_num, num_requests;
    		ss >> video_num >> endpoint_num >> num_requests;
    		vector<int> tmp ;
    		tmp.push_back(video_num);
    		tmp.push_back(endpoint_num);
    		tmp.push_back(num_requests);
    		requests.push_back(tmp);
    		endpoint_video[endpoint_num][video_num] = num_requests;
    	}

      //cout << line << '\n';
    }
    myfile.close();
    //cout<<nv<<" "<<ne<<" "<<nr<<" "<<nc<<" "<<nx<<"\n";
  }

  else cout << "Unable to open input file for the second time\n";

  //cout<<"Parsed input for the second time\n";
  //Calculate score

/*  cout<<"Printing cache video\n";
  for (int i=0; i<=nc; i++) {
  	for (int j=0; j<nv; j++) {
  		cout<<cache_video[i][j]<<" ";
  	}
  	cout<<endl;
  }*/
/*  cout<<"Printing endpoint cache\n";
  for (int i=0; i<ne; i++) {
  	for (int j=0; j<=nc; j++) {
  		cout<<endpoint_cache[i][j]<<" ";
  	}
  	cout<<endl;
  }*/
  float score = 0.0;
  long long int numerator = 0, denom = 0;
  for (int i=0; i<requests.size(); i++) {
  		int video_num = requests[i][0];
  		int endpoint_num = requests[i][1];
  		int num_requests = requests[i][2];
  		denom += num_requests;
  		int min_lat = 100000000;
  		for (int i=0; i<=nc; i++) {
  			if (cache_video[i][video_num]) {
  				min_lat = min (min_lat, endpoint_cache[endpoint_num][i]);
  			}
  		}
  		cout<<"min_lat: "<<min_lat<<" for endpoint: "<<endpoint_num<<endl;
  		numerator += (num_requests * (endpoint_cache[endpoint_num][nc] - min_lat) );
  }
  score = (float) numerator / denom;
  cout<<"numerator: "<<numerator<<" denom: "<<denom<<endl;
  cout<<"score: "<<score<<endl;

  return 0;
}
