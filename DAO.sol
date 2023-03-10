// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract DAO
{
    struct comments 
    {
        address from;
        string content;
    }

    struct post
    {
        // posts itself
        address from;
        uint64 id;
        string title;
        string message;

        // for comments
        uint64 last_comment_id;
        comments[] reply;

        // likes & dislikes
        uint64 likes;
        uint64 dislikes;
        mapping(address => int) status;
    } 
    uint64 last_id = 0;
    mapping(uint64 => post) public posts;

    struct people
    {
        string name;
        string password;
        int64 token;
        int id;
    }
    mapping(address => people) public users;

    struct vote
    {
        address creator;
        string description;

        mapping(address => int64) status;
        int64 yes;
        int64 no;
        
        uint256 deadline;

        bool pass;
    }
    int64 voting_cost = 50;
    uint256 _debatingPeriod = 2 weeks;
    int current_id = 1;
    vote[] votes;

    function assign_new_user(address who, string memory _name, string memory _password) public
    {
        users[who] = people(_name, _password, 0, current_id);
        current_id++;
    }


    function exist(address who) public view returns (bool)
    {
        return users[who].id != 0;
    }

   
    // post & comment

    function post_something(address _from, string memory _title, string memory _message) public
    {
        if(exist(_from))
        {
            posts[last_id].from = _from;
            posts[last_id].id = last_id;
            posts[last_id].title = _title;
            posts[last_id].message = _message;
            posts[last_id].last_comment_id = 0;
            posts[last_id].likes = 0;
            posts[last_id].dislikes = 0;
            last_id++;
            users[_from].token++;
        }
    }

    function like(uint64 post_id) public returns (bool)
    {
        if(posts[post_id].status[msg.sender] == 0)
        {
            posts[post_id].likes++;
            posts[post_id].status[msg.sender] = 1;
            users[posts[post_id].from].token++;
            return true;
        }
        else
        {
            return false;
        }   
    }

    function dislike(uint64 post_id) public returns (bool)
    {
        if(posts[post_id].status[msg.sender] == 0)
        {
            posts[post_id].dislikes++;
            posts[post_id].status[msg.sender] = -1;
            users[posts[post_id].from].token--;
            return true;
        }
        else
        {
            return false;
        }   
    }

    function cancel_like_or_dislike(uint64 post_id) public
    {
        if(posts[post_id].status[msg.sender] == 1)
        {
            posts[post_id].likes--;
            users[posts[post_id].from].token--;
        }
        if(posts[post_id].status[msg.sender] == -1)
        {
            posts[post_id].dislikes--;
            users[posts[post_id].from].token++;
        }
        posts[post_id].status[msg.sender] = 0;
    }

    function show_post(uint64 post_id) public view 
    returns (string memory, string memory, string memory, uint64, uint64)
    {
        return 
        (
            users[posts[post_id].from].name, 
            posts[post_id].title, 
            posts[post_id].message, 
            posts[post_id].likes, 
            posts[post_id].dislikes
        );
    }

    function comment_something(uint64 post_id, address _from, string memory _context) public
    {
        comments memory to_comment = comments(_from, _context);
        posts[post_id].reply.push(to_comment);
        posts[post_id].last_comment_id += 1;
        users[posts[post_id].from].token += 3;
    }

    function show_comment(uint64 post_id, uint64 comment_id) public view returns (string memory, string memory)
    {
        return (users[posts[post_id].reply[comment_id].from].name,
                posts[post_id].reply[comment_id].content);
    }

    function amount_of_posts() public view returns (uint64)
    {
        return last_id + 1;
    }
    function amount_of_comment(uint64 id) public view returns (uint64)
    {
        return posts[id].last_comment_id;
    }
    // voting system
    function create_pool(address from, string memory _description) public returns (bool)
    {
        if(users[from].token >= voting_cost)
        {
            uint256 idx = votes.length;
            votes.push();
            vote storage to_create = votes[idx];
            to_create.creator = from;
            to_create.description = _description;
            to_create.yes = 0;
            to_create.no = 0; 
            to_create.deadline = block.timestamp + _debatingPeriod;
            to_create.pass = false;

            users[from].token -= voting_cost;
            return true;
        }
        return false;
    }

    function show_pool(uint256 x) public returns(string memory, int64, int64, string memory)
    {
        if(x >= votes.length)
        {
            return ("Vote does not exists", -1, -1, "");
        }
        string memory status;
        if (block.timestamp > votes[x].deadline)
        {
            if(votes[x].yes > votes[x].no && votes[x].pass == false)
            {
                votes[x].pass = true;
                users[votes[x].creator].token += voting_cost;
            }
            if (votes[x].yes > votes[x].no)
            {
                status = "vote pass";
            }
            else
            {
                status = "vote didn't pass";
            }
        }
        else
        {
            status = "voting...";
        }
        return (votes[x].description, votes[x].yes, votes[x].no, status);
    }

    function vote_yes(address from, uint64 vote_id, int64 amount) public
    {
        if (block.timestamp <= votes[vote_id].deadline && votes[vote_id].status[from] == 0 && amount > 0)
        {
            users[from].token -= amount * amount;
            votes[vote_id].status[from] += amount;
            votes[vote_id].yes += amount;
        }
    }
    function vote_no(address from, uint64 vote_id, int64 amount) public
    {
        if (block.timestamp <= votes[vote_id].deadline && votes[vote_id].status[from] == 0 && amount > 0)
        {
            users[from].token -= amount * amount;
            votes[vote_id].status[from] -= amount;
            votes[vote_id].no += amount;
        }
    }
}
